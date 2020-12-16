#lang racket/base

(require
 (rename-in
  "load-ffi.rkt"
  [get-empty-line-height render-get-empty-line-height]))
(require racket/generator)
(require ffi/unsafe)
(require racket/place/dynamic)
(require "ffi-types.rkt")
                    
(provide
 place-main
 render-init
 render-context-create
 render-context-destroy
 render-draw-line-in-context
 render-get-line-info)

(struct render-context (id width height data ctx))
(struct render-line-info (id info))

(define (make-sequence-generator) (sequence->generator (in-naturals)))

(define get-context-id (make-sequence-generator))
(define contexts (make-hasheqv))

(define get-line-id (make-sequence-generator))
(define lines (make-hasheqv))

(define bufmgr-place (box #f))

(define libname "libred-render-core-text")

(define (render-init bufmgr-pch)
  (set-box! bufmgr-place bufmgr-pch)
  (lib-reload libname)
  (lib-init)
  0
  )

(define (render-context-get-data cid)
  (let ([context (hash-ref contexts cid)])
    (render-context-data context)))

(define (render-context-create width height)
  (let* ([data (malloc _byte (* width height 4) 'raw)]
         [ctx (context-create width height data)]
         [id (get-context-id)]
         [context (render-context id width height data ctx)])
    (hash-set! contexts id context)
    id))

(define (render-context-destroy cid)
  (let ([context (hash-ref contexts cid)])
    (context-destroy (render-context-ctx context))
    (hash-remove! contexts cid)))

(define (render-draw-line-in-context cid lid x y)
  (let* ([context (hash-ref contexts cid)]
         [ctx (render-context-ctx context)]
         [line (hash-ref lines lid)])
    (draw-line ctx (render-line-info-info line) x y)))

(define (render-get-line-info data)
  (let* ([id (get-line-id)]        
         [info (get-line-info data)]
         [line-info (render-line-info id info)])
    (hash-set! lines id line-info)
    id))

(define (render-get-line-height lid)
  (let* ([info (hash-ref lines lid)]
         [lineInfo (render-line-info-info info)])
    (+
     (lineInfo-ascent lineInfo)
     (lineInfo-descent lineInfo)
     (lineInfo-leading lineInfo))))
  

(define (render-get-total-line-height lids)
  (for/sum ([lid lids])
    (render-get-line-height lid)))

(define cmds
  (make-hasheq
   (list
    `(render-init . ,render-init)
    `(render-context-create . ,render-context-create)
    `(render-context-destroy . ,render-context-destroy)
    `(render-get-line-info . ,render-get-line-info)
    `(render-draw-line-in-context . ,render-draw-line-in-context)
    `(render-get-empty-line-height . ,render-get-empty-line-height)
    `(render-get-total-line-height . ,render-get-total-line-height)
    `(render-get-line-height . ,render-get-line-height)
    `(render-context-get-data . ,render-context-get-data))))

(define (handle-msg pch msg)
  (if (or (not (list? msg)) (null? msg))
      (error "msg not a list -- " msg)
      (let* ([cmd (car msg)]
             [f (hash-ref cmds cmd (λ () #f))])
        (if (not f)
            (error "command not found -- " cmd)
            (let ([result (apply f (cdr msg))])
              (place-channel-put pch result))))))

(define (place-main dispatch-pch)
  (let loop ()
    (let ([ev1 (wrap-evt dispatch-pch (λ (msg) (handle-msg dispatch-pch msg)))]
          [bufmgr-pch (unbox bufmgr-place)])
      (if bufmgr-pch
          (let ([ev2 (wrap-evt bufmgr-pch (λ (msg) (handle-msg bufmgr-pch msg)))])
            (sync ev1 ev2)
            (loop))
          (begin
            (sync ev1)
            (loop))))))


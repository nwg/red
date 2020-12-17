#lang racket/base

(require racket/place/dynamic)
(require racket/set)
(require racket/runtime-path)
(require "callbacks.rkt")

(provide dispatch-init dispatch-run)

(define client-place #f)
(define bufmgr-place #f)
(define render-place #f)

(define init-completion #f)

(define-runtime-path client-place-module "client-place.rkt")
(define-runtime-path bufmgr-place-module "bufmgr-place.rkt")
(define-runtime-path render-place-module "render-place.rkt")

(define (dispatch-init client-run-fp tile-did-change-fp interp-stdin-fd interp-stdout-fd)

  (define-values (c2b b2c) (place-channel))
  
  (set!
   client-place
   (dynamic-place client-place-module 'place-main))
  
  (set! bufmgr-place (dynamic-place bufmgr-place-module 'place-main))
  
  (place-channel-put client-place c2b)
  (place-channel-put client-place client-run-fp)
  
  (define client-sync
    (thread
     (λ ()
       (define rdy (place-channel-get client-place))
       (when (not (eq? rdy 'ready))
         (error "Client place not initialized properly -- got" rdy)))))

  (set! init-completion
   (thread
    (λ ()
      (callbacks-init tile-did-change-fp)
  
      (set! render-place (dynamic-place render-place-module 'place-main))
      (let-values ([(render-to-bufmgr bufmgr-to-render) (place-channel)])
        (place-channel-put render-place `(render-init ,render-to-bufmgr))
        (let ([init-result (place-channel-get render-place)])
          (when (not (= 0 init-result))
            (error "Bad init from render\n")))
      
        (place-channel-put bufmgr-place bufmgr-to-render)
        (place-channel-put bufmgr-place b2c)
        (let ([result (place-channel-get bufmgr-place)])
          (when (not (eq? result 'ok))
            (error "bufmgr failed to initialize\n")))))))

  (thread-wait client-sync)
  (wait-for-full-init)
    
  0)

(define (wait-for-full-init)
  (thread-wait init-completion))

(define (handle-msg pch msg)
  (let* ([cmd (car msg)]
         [args (cdr msg)]
         [result (callbacks-handle cmd args)])
    (place-channel-put pch result)))

(define (dispatch-run)
  (wait-for-full-init)
  (let loop ()
    (sync
     (wrap-evt bufmgr-place (λ (msg) (handle-msg bufmgr-place msg))))    
    (loop)))

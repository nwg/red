#lang racket/base

(require racket/place/dynamic)
(require racket/set)
(require racket/runtime-path)

(provide dispatch-init dispatch-run test-dispatch)

(define client-bufmgr-cmds
  (seteq
   'register-memory 'unregister-memory 'open-portal 'close-portal
   'create-buffer 'buffer-open-file 'draw-buffer-in-portal 'set-current-bounds
   'get-render-info))

(define client-place #f)
(define client-place-wrapped #f)

(define bufmgr-place #f)
(define render-place #f)

(define init-completion #f)

(define-runtime-path client-place-module "client-place.rkt")
(define-runtime-path bufmgr-place-module "bufmgr-place.rkt")
(define-runtime-path render-place-module "render-place.rkt")

(define (dispatch-init client-run-fp interp-stdin-fd interp-stdout-fd)

  (set!
   client-place
   (dynamic-place client-place-module 'place-main))
  
  (place-channel-put client-place client-run-fp)

  (define client-sync
    (thread
     (λ ()
       (define rdy (place-channel-get client-place))
       (when (not (eq? rdy 'ready))
         (error "Client place not initialized properly -- got" rdy)))))
  
  (set!
   client-place-wrapped
   (wrap-evt
    client-place
    (λ (v) (values client-place v))))

  (thread-wait client-sync)  
    
  (set! render-place (dynamic-place render-place-module 'place-main))
  (set! init-completion
   (thread
    (λ ()
      (let-values ([(render-to-bufmgr bufmgr-to-render) (place-channel)])
      (place-channel-put render-place `(render-init ,render-to-bufmgr))
      (let ([init-result (place-channel-get render-place)])
        (when (not (= 0 init-result))
          (error "Bad init from render\n")))
      (set! bufmgr-place (dynamic-place bufmgr-place-module 'place-main))
      (place-channel-put bufmgr-place `(bufmgr-init ,bufmgr-to-render))
      (let ([init-result (place-channel-get bufmgr-place)])
        (printf "Got init from bufmgr\n")
        (when (not (= 0 init-result))
          (error "Bad init from bufmgr\n")))))))

  0)

(define (wait-for-full-init)
  (thread-wait init-completion))

(define (target-place-for-cmd source-place cmd)
  (cond
    [(eq? source-place client-place)
      (cond
        [(set-member? client-bufmgr-cmds cmd) bufmgr-place]
        [else (error "Not a valid command" cmd)])]
    [else (error "Not a valid source-place")]))

(define (test-dispatch)
  0)

(define (dispatch-run)
  (wait-for-full-init)
  (let loop ()
    (let-values ([(p msg) (sync client-place-wrapped)])
      (let* ([cmd (car msg)]
             [args (cdr msg)]
             [target-place (target-place-for-cmd p cmd)])
        (place-channel-put target-place (cons cmd args))
        (let ([result (place-channel-get target-place)])
          (place-channel-put p result))))
    (loop)))

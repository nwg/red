#lang racket/base

(require ffi/unsafe)
(require racket/place)
(require "ffi.rkt")
(require syntax/location)
(require racket/set)

(provide dispatch-init dispatch-run test-dispatch)

(define client-bufmgr-cmds
  (seteq
   'register-memory 'unregister-memory 'open-portal 'close-portal
   'create-buffer 'buffer-open-file 'draw-buffer-in-portal))

(module myplace racket/base
  (printf "In module load of client-place\n")
  (provide place-main)
  (require "ffi.rkt")
  (require ffi/unsafe)
  (require racket/place)

  (define (place-main ch)
    (define (getproc)
      (place-channel-get ch))
    (define (putproc v)
      (place-channel-put ch v))

    (define client-run-fp (place-channel-get ch))
    (define run-client-fn (cast client-run-fp _uintptr _clientproc))
    
    (run-client-fn getproc putproc)
    (error "Should not get here")))

(module bufmgr-place-module racket/base
  (provide place-main)
  (require red-bufmgr))


(define client-place #f)
(define client-place-wrapped #f)

(define bufmgr-place #f)

(define (dispatch-init client-run-fp interp-stdin-fd interp-stdout-fd)
  (printf "In dispatch-init\n")

  (printf "Starting client place\n")
  (set!
   client-place
   (dynamic-place (quote-module-path myplace) 'place-main))
  (place-channel-put client-place client-run-fp)

  (set!
   client-place-wrapped
   (wrap-evt
    client-place
    (λ (v) (values client-place v))))

  (set! bufmgr-place (dynamic-place (quote-module-path bufmgr-place-module) 'place-main))
  (define rdy (place-channel-get client-place))
  (when (not (eq? rdy 'ready))
    (error "Client place not initialized properly -- got" rdy))
  
  0)

(define (target-place-for-cmd source-place cmd)
  (cond
    [(eq? source-place client-place)
      (cond
        [(set-member? client-bufmgr-cmds cmd) bufmgr-place]
        [else (error "Not a valid command" cmd)])]
    [else (error "Not a valid source-place")]))

(define (test-dispatch)
  0)

(define-namespace-anchor anchor)
(define ns (namespace-anchor->namespace anchor))

(define (dispatch-run)
  (let loop ()
    (let-values ([(p msg) (sync client-place-wrapped)])
      (let* ([cmd (car msg)]
             [args (cdr msg)]
             [target-place (target-place-for-cmd p cmd)])
        (place-channel-put target-place (cons cmd args))
        (let ([result (place-channel-get target-place)])
          (place-channel-put p result))))
    (loop)))

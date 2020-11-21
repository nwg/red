#lang racket/base

(require ffi/unsafe)
(require racket/place)
(require "ffi.rkt")
(require syntax/location)

(provide dispatch-init dispatch-run test-dispatch)

(printf "loading module on thread ~X\n" (pthread_self))

(module myplace racket/base
  (provide place-main)
  (require "ffi.rkt")
  (require syntax/location)

  (module stash racket/base
    (provide client-channel)
    (define client-channel (make-parameter #f)))

  (require 'stash)
  
  (define (place-main ch)
    (client-channel ch)
    (red_client_run_from_racket (quote-module-path stash))
    (error "Should not get here")))

(define client-place #f)
(define client-place-wrapped #f)
  
(define (dispatch-init client-run-fp interp-stdin-fd interp-stdout-fd)
  (printf "dispatch-init on thread ~X\n" (pthread_self))

  (set!
   client-place
   (dynamic-place (quote-module-path myplace) 'place-main))

  (set!
   client-place-wrapped
   (wrap-evt
    client-place
    (λ (v) (values client-place v))))

  (define rdy (place-channel-get client-place))
  (when (not (eq? rdy 'ready))
    (error "Client place not initialized properly -- got" rdy))
  
  0)

(define (test-dispatch)
  (printf "test-dispatch on thread ~X\n" (pthread_self))
  0)

(define-namespace-anchor anchor)
(define ns (namespace-anchor->namespace anchor))

(define (dispatch-run)
  (let loop ()
    (printf "Looping\n")
    (let-values ([(p msg) (sync client-place-wrapped)])
      (let* ([cmd (eval (car msg) ns)]
             [args (cdr msg)])
        (printf "Applying ~s to ~s\n" args cmd)
        (let ([result (apply cmd args)])
          (printf "Putting\n")
          (place-channel-put p result))))
    (loop)))

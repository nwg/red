#lang racket/base

(require ffi/unsafe)
(require racket/place)
(require "ffi.rkt")

(provide dispatch-init dispatch-run)

(define run-client-place #f)

(define (put-wrapper pch . args)
  (printf "put on thread ~X\n" (pthread_self))
  (apply place-channel-put pch args))

(define client-place
  (place
   ch
   (printf "In client-place\n")
   (red_client_run_from_racket ch put-wrapper place-channel-get)
   (error "Should not get here")))
  
(define client-place-wrapped
  (wrap-evt
   client-place
   (λ (v) (values client-place v))))
  
(define (dispatch-init client-run-fp interp-stdin-fd interp-stdout-fd)
  (printf "dispatch-init on thread ~X\n" (pthread_self))
  (define rdy (place-channel-get client-place))
  (printf "Got ready ~s\n" rdy)
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

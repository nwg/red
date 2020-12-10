#lang racket/base

(provide place-main)
(require ffi/unsafe)
(require racket/place/dynamic)

(define _putproc
  (_cprocedure (list _racket) _void))

(define _getproc
  (_cprocedure '() _racket))

(define _clientproc
  (_cprocedure (list _getproc _putproc) _void))

(define (place-main ch)
  (define (getproc)
    (place-channel-get ch))
  (define (putproc v)
    (place-channel-put ch v))

  (define client-run-fp (place-channel-get ch))
  (define run-client-fn (cast client-run-fp _uintptr _clientproc))
  
  (run-client-fn getproc putproc)
  (error "Should not get here"))


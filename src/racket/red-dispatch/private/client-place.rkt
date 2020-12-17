#lang racket/base

(provide place-main)
(require ffi/unsafe)
(require racket/place/dynamic)

(define _putproc
  (_cprocedure (list _racket) _void))

(define _getproc
  (_cprocedure '() _racket))

(define _clientproc
  (_cprocedure (list _putproc _getproc _putproc) _void))

(define (place-main ch)
  (define bufmgr-place (place-channel-get ch))

  (define (rdyproc v)
    (place-channel-put ch v))
  
  (define (getproc)
    (place-channel-get bufmgr-place))
  (define (putproc v)
    (place-channel-put bufmgr-place v))

  (define client-run-fp (place-channel-get ch))
  (define run-client-fn (cast client-run-fp _uintptr _clientproc))

  (run-client-fn rdyproc getproc putproc)
  (error "Should not get here"))


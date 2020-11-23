#lang racket/base

(require ffi/unsafe ffi/unsafe/define)

(provide red_client_run_from_racket)

(define-ffi-definer define-red-dispatch (ffi-lib #f))

(define _putproc
  (_cprocedure (list _racket) _void))

(define _getproc
  (_cprocedure '() _racket))

(define-red-dispatch
  red_client_run_from_racket
  (_fun _getproc _putproc -> _int))

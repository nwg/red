#lang racket/base

(require ffi/unsafe ffi/unsafe/define)

(provide _clientproc)

(define-ffi-definer define-red-dispatch (ffi-lib #f))

(define _putproc
  (_cprocedure (list _racket) _void))

(define _getproc
  (_cprocedure '() _racket))

(define _clientproc
  (_cprocedure (list _getproc _putproc) _void))

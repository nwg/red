#lang racket/base

(require ffi/unsafe ffi/unsafe/define)

(provide red_client_run_from_racket pthread_self)

(define-ffi-definer define-red-dispatch (ffi-lib #f))

(define-red-dispatch
  red_client_run_from_racket
  (_fun _racket _racket _racket -> _int))

(define-red-dispatch
  pthread_self
  (_fun -> _uintptr))

#lang racket/base

(require ffi/unsafe ffi/unsafe/define)

(provide red_client_run_from_racket)

(define-ffi-definer define-red-dispatch (ffi-lib #f))

(define-red-dispatch
  red_client_run_from_racket
  (_fun _racket -> _int))

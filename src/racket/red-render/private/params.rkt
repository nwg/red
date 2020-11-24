#lang racket/base

(provide
 current-render-lib
 current-render-custodian
 current-render-ffi-ns)

(define current-render-lib (make-parameter #f))
(define current-render-custodian (make-parameter #f))
(define current-render-ffi-ns (make-parameter #f))


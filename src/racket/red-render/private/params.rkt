#lang racket/base

(provide
 current-render-lib
 current-render-custodian
 current-render-ffi-ns)

(define current-render-lib (box #f))
(define current-render-custodian (box #f))
(define current-render-ffi-ns (box #f))


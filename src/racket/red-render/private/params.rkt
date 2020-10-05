#lang racket/base

(provide
 current-render-lib
 current-render-custodian)

(define current-render-lib (make-parameter #f))
(define current-render-custodian (make-parameter (make-custodian)))


#lang racket/base

(require ffi/unsafe)
(provide lineInfo?
         make-lineInfo
         (struct-out lineInfo)
         empty-lineInfo
         _lineInfo-pointer
         _lineRef
         lineRef?)

(define-cpointer-type _lineRef)

(define-cstruct _lineInfo ([ascent _double]
                           [descent _double]
                           [leading _double]
                           [width _double]
                           [lineRef _lineRef/null]))

(define (empty-lineInfo)
  (make-lineInfo 0.0 0.0 0.0 0.0 #f))

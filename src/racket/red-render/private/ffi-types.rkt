#lang racket/base

(require ffi/unsafe)
(provide lineInfo?
         make-lineInfo
         (struct-out lineInfo)
         _lineInfo-pointer)

(define-cstruct _lineInfo ([ascent _double]
                           [descent _double]
                           [leading _double]
                           [width _double]))


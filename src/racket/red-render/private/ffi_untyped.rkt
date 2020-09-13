#lang racket/base

(provide lineInfo? make-lineInfo)
(require ffi/unsafe)

(define-cstruct _lineInfo ([ascent _double]
                           [descent _double]
                           [leading _double]
                           [width _double]))


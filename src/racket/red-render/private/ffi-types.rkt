#lang racket/base

(require ffi/unsafe)
(require "../types.rkt")
(provide lineInfo?
         make-lineInfo
         (struct-out lineInfo)
         empty-lineInfo
         _lineInfo-pointer
         _CTLineRef
         CTLineRef?
         _fontInfo-pointer
         empty-fontInfo
         lineInfo->render-line-info
         (struct-out fontInfo))

(define-cpointer-type _CTLineRef)

(define-cstruct _lineInfo ([ascent _double]
                           [descent _double]
                           [leading _double]
                           [width _double]

                           [lineRef _CTLineRef/null]))

(define-cstruct _fontInfo ([ascent _double]
                           [descent _double]
                           [leading _double]))

(define (lineInfo->render-line-info info)
  (render-line-info
   (lineInfo-ascent info)
   (lineInfo-descent info)
   (lineInfo-leading info)
   (lineInfo-width info)))
   
(define (empty-lineInfo)
  (make-lineInfo 0.0 0.0 0.0 0.0 #f))

(define (empty-fontInfo)
  (make-fontInfo 0.0 0.0 0.0))

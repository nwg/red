#lang racket/base

(provide (struct-out render-line-info)
         (struct-out render-font-info)
         render-line-info-height
         render-font-info-height)

(struct render-line-info (ascent descent leading width) #:prefab)
(struct render-font-info (ascent descent leading) #:prefab)

(define (render-line-info-height info)
  (+
   (render-line-info-ascent info)
   (render-line-info-descent info)
   (render-line-info-leading info)))

(define (render-font-info-height info)
  (+
   (render-font-info-ascent info)
   (render-font-info-descent info)
   (render-font-info-leading info)))

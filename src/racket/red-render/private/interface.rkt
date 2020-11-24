#lang racket/base

;; (provide get-line-info)

(require "load-ffi.rkt")
(provide
 render-init
 get-line-info
 render-context-create
 render-context-destroy
 render-draw-line-in-context
 (struct-out point))


(struct render-context (width height ctx))
(struct point (x y))

(define (render-context-create addr width height)
  (let* ([ctx (context-create width height addr)]
         [context (render-context width height ctx)])
    context))

(define (render-context-destroy context)
  '())

(define (render-draw-line-in-context context point lineInfo)
  (let ([ctx (render-context-ctx context)])
    (draw-line ctx lineInfo (point-x point) (point-y point))))

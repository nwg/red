#lang racket/base

;; (provide get-line-info)

(require "load-ffi.rkt")
(provide get-line-info
         render-context-create
         render-context-destroy
         render-draw-line-in-context
         (struct-out point))


(struct render-context (width height ctx))
(struct point (x y))

(render-reload "libred-render-core-text")

((render-get-func 'red_render_init))

(define (render-context-create addr width height)
  (let* ([ctx (context-create width height addr)]
         [context (render-context width height ctx)])
    context))

(define (render-context-destroy context)
  '())

(define (render-draw-line-in-context context point lineInfo)
  (let ([ctx (render-context-ctx context)])
    (draw-line ctx lineInfo (point-x point) (point-y point))))

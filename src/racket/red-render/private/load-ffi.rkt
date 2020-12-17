#lang racket/base

(require racket/runtime-path)
(provide
 lib-init
 lib-reload
 get-line-info
 context-create
 context-destroy
 draw-line
 clear-rect
 get-font-info
 (struct-out lineInfo))

(require "params.rkt")
(require "ffi-types.rkt")

(define-runtime-module-path ffi "ffi.rkt")
(define-runtime-module-path params "params.rkt")

(define-namespace-anchor a)

(define (lib-reload name)
  (when (unbox current-render-custodian)
    (custodian-shutdown-all (unbox current-render-custodian)))

  (set-box! current-render-lib name)
  (set-box! current-render-custodian (make-custodian))

  (let ([ns (make-empty-namespace)])
    (namespace-attach-module (namespace-anchor->empty-namespace a)
                             params
                             ns)
    (parameterize ([current-namespace ns])
      (namespace-require ffi))
    (set-box! current-render-ffi-ns ns)))

(define (lib-init)
  ((render-get-func 'red_render_init)))
  
(define (render-get-func sym)
  (let ([ns (unbox current-render-ffi-ns)])
    (if ns
        (namespace-variable-value sym #t #f ns)
        #f)))

(define (get-line-info s)
  (let* ([bs (string->bytes/utf-8 s)]
         [info (empty-lineInfo)])
    ((render-get-func 'red_render_get_line_info) bs (bytes-length bs) info)))
    
(define (context-create width height buf)
  ((render-get-func 'red_render_create_context) width height buf))

(define (context-destroy ctx)
  ((render-get-func 'red_render_destroy_context) ctx))

(define (draw-line ctx info x y)
  ((render-get-func 'red_render_draw_line) ctx info x y))

(define (clear-rect ctx x y w h)
  ((render-get-func 'red_render_clear_rect) ctx x y w h))

(define (get-font-info)
  (let ([info (empty-fontInfo)])
    ((render-get-func 'red_render_get_font_info) info)))

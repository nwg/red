#lang racket/base

(require racket/runtime-path)
(provide
 render-init
 get-line-info
 context-create
 draw-line
 get-line-height
 (struct-out lineInfo))

(require "params.rkt")
(require "ffi-types.rkt")

(define libname "libred-render-core-text")

(define-runtime-module-path ffi "ffi.rkt")
(define-runtime-module-path params "params.rkt")

(define-namespace-anchor a)

(define (render-reload name)
  (when (current-render-custodian)
    (custodian-shutdown-all (current-render-custodian)))

  (current-render-lib name)
  (current-render-custodian (make-custodian))

  (let ([ns (make-empty-namespace)])
    (namespace-attach-module (namespace-anchor->empty-namespace a)
                             params
                             ns)
    (parameterize ([current-namespace ns])
      (namespace-require ffi))
    (current-render-ffi-ns ns)))

(define (render-init)
  (render-reload libname)
  ((render-get-func 'red_render_init)))
  
(define (render-get-func sym)
  (let ([ns (current-render-ffi-ns)])
    (if ns
        (namespace-variable-value sym #t #f ns)
        #f)))

(define (get-line-info s)
  (let* ([bs (string->bytes/utf-8 s)]
         [info (empty-lineInfo)])
    ((render-get-func 'red_render_get_line_info) bs (bytes-length bs) info)))
    
(define (context-create width height buf)
  ((render-get-func 'red_render_create_context) width height buf))

(define (draw-line ctx info x y)
  ((render-get-func 'red_render_draw_line) ctx info x y))

(define (get-line-height)
  ((render-get-func 'red_render_get_line_height)))

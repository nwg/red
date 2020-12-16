#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define
         "params.rkt"
         "ffi-types.rkt")

;; (require/typed "ffi_untyped.rkt"
;;   [#:opaque lineInfo lineInfo?]
;;   [lineInfo-ascent Real])

(provide red_render_init
         red_render_get_line_info
         red_render_create_context
         red_render_destroy_context
         red_render_draw_line
         red_render_get_line_height
         red_render_clear_rect)

(define-ffi-definer
  define-red-render
  (ffi-lib
   (unbox current-render-lib)
   #:custodian (unbox current-render-custodian)))

(define (check f)
 (λ (v who)
     (unless (f v)
       (error who "failed: ~a" v))
     v))

(define check-zero? (check zero?))
(define _ctx-pointer (_cpointer 'ctx))

(define-red-render
  red_render_init
  (_fun -> (r : _int)
        -> (check-zero? r 'red_render_init)))

(define-red-render
  red_render_get_line_info
  (_fun _bytes _int (info : _lineInfo-pointer) -> _void
        -> info))


(define-red-render
  red_render_create_context
  (_fun _int _int _pointer -> _ctx-pointer))

(define-red-render
  red_render_draw_line
  (_fun _ctx-pointer _lineInfo-pointer _double* _double* -> _void))

(define-red-render
  red_render_clear_rect
  (_fun _ctx-pointer _int _int _int _int -> _void))

(define-red-render
  red_render_get_line_height
  (_fun -> _double))

(define-red-render
  red_render_destroy_context
  (_fun _ctx-pointer -> _void))

#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define
         "params.rkt"
         "ffi-types.rkt")

;; (require/typed "ffi_untyped.rkt"
;;   [#:opaque lineInfo lineInfo?]
;;   [lineInfo-ascent Real])

(provide red_render_init
         red_render_get_line_info)

(define-ffi-definer
  define-red-render
  (ffi-lib
   (current-render-lib)
   #:custodian (current-render-custodian)))

(define (check f)
 (λ (v who)
     (unless (f v)
       (error who "failed: ~a" v))
     v))

(define check-zero? (check zero?))

(define-red-render
  red_render_init
  (_fun -> (r : _int)
        -> (check-zero? r 'red_render_init)))

(define-red-render
  red_render_get_line_info
  (_fun _bytes _int (info : _lineInfo-pointer) -> _void
        -> info))


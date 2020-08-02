#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define)

;; (require/typed "ffi_untyped.rkt"
;;   [#:opaque lineInfo lineInfo?]
;;   [lineInfo-ascent Real])

(provide red_render_init
         red_render_get_line_info
         lineInfo?
         make-lineInfo
         lineInfo-ascent
         (struct-out lineInfo)
         make-lineInfo)

(define-ffi-definer define-red-render (ffi-lib "libred-render-core-text"))

(define (check f)
 (λ (v who)
     (unless (f v)
       (error who "failed: ~a" v))
     v))

(define check-zero? (check zero?))

(define-cstruct _lineInfo ([ascent _double]
                           [descent _double]
                           [leading _double]
                           [width _double]))

(define-red-render
  red_render_init
  (_fun -> (r : _int)
        -> (check-zero? r 'red_render_init)))


(define-red-render
  red_render_get_line_info
  (_fun _bytes _int (info : _lineInfo-pointer) -> _void
        -> info))

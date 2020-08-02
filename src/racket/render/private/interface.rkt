#lang typed/racket/base

;; (require "ffi.rkt")
(provide get-line-info)

(require/typed "ffi.rkt"
  [#:opaque lineInfo lineInfo?]
  [make-lineInfo (-> Float Float Float Float lineInfo)]
  [lineInfo-ascent (-> lineInfo Real)]
  [lineInfo-descent (-> lineInfo Real)]
  [red_render_init (-> Integer)]
  [red_render_get_line_info (-> Bytes Integer lineInfo lineInfo)])

(when (not (= (red_render_init) 0))
    (error "Could not initialize renderer"))

(struct LineInfo ([l : lineInfo]) #:transparent)

(: get-line-info (-> Bytes Integer LineInfo LineInfo))
(define (get-line-info bs len info)
  (let ([l (red_render_get_line_info bs len (LineInfo-l info))])
    (LineInfo l)))

(: make-empty-LineInfo (-> LineInfo))
(define (make-empty-LineInfo)
  (LineInfo (make-lineInfo 0.0 0.0 0.0 0.0)))

(let* ([bs (string->bytes/utf-8 "something")]
       [info1 (make-empty-LineInfo)]
       [info2 (get-line-info bs (bytes-length bs) info1)]
       [cinfo (LineInfo-l info2)])
  (displayln (+ (lineInfo-ascent cinfo) (lineInfo-descent cinfo))))
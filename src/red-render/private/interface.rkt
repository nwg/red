#lang typed/racket/base

;; (require "ffi.rkt")
(provide get-line-info)

(require/typed "ffi.rkt"
  [#:opaque lineInfo lineInfo?]
  [lineInfo-ascent (-> lineInfo Real)]
  [red_render_init (-> Integer)]
  [red_render_get_line_info (-> Bytes Integer lineInfo)])
    
(red_render_init)

(struct LineInfo ([l : lineInfo]) #:transparent)

(: get-line-info (-> Bytes Integer LineInfo))
(define (get-line-info bs len)
  (let ([l (red_render_get_line_info bs len)])
    (LineInfo l)))
    

(let* ([bs (string->bytes/utf-8 "something")]
       [info (get-line-info bs (bytes-length bs))])
  (displayln (lineInfo-ascent (LineInfo-l info))))

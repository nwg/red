#lang racket/base

(require racket/runtime-path)
(provide render-reload get-func get-line-height)
(require "params.rkt")
(require "ffi-types.rkt")

;; (define ffi (make-resolved-module-path (path->complete-path (string->path "private/ffi.rkt"))))

(define-runtime-module-path ffi "ffi.rkt")
(define-runtime-module-path params "params.rkt")


(define-namespace-anchor a)

;; (define abc 'hello)
;; (namespace-variable-value 'abc)

(define ns #f)

(define (render-reload name)
  (printf "Shutting down custodian\n")
  (custodian-shutdown-all (current-render-custodian))

  (current-render-lib name)
  (current-render-custodian (make-custodian))

  (set! ns (make-empty-namespace))
  (namespace-attach-module (namespace-anchor->empty-namespace a)
                           params
                           ns)
  (parameterize ([current-namespace ns])
    (namespace-require ffi)))

(define (get-func sym)
  (if ns
      (namespace-variable-value sym #t #f ns)
      #f))

(define (get-line-height s)
  (let* ([bs (string->bytes/utf-8 "something")]
         [info (make-lineInfo 0.0 0.0 0.0 0.0)])
    ((get-func 'red_render_get_line_info) bs (bytes-length bs) info)
    (+ (lineInfo-ascent info) (lineInfo-descent info))))

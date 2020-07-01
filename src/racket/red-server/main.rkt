#lang racket

(require racket/place)
(require racket/runtime-path)

(provide red-server-run)

(define-runtime-path data-file "sample.iso8859-1")

(define f (open-input-file data-file #:mode 'text))
(define r (reencode-input-port f "ISO_8859-1"))

(define (red-server-run)
    (read-line r 'any))

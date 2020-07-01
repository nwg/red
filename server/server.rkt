#lang racket

(require racket/place)

(define f (open-input-file "sample.iso8859-1" #:mode 'text))
(define r (reencode-input-port f "ISO_8859-1"))
(read-line r 'any)

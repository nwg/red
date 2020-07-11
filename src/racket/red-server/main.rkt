#lang racket

(require racket/place)
(require racket/runtime-path)

(provide red-server-run)

(define-runtime-path data-file "sample.iso8859-1")

(define (test-encoding)
    (define f (open-input-file data-file #:mode 'text))
    (define r (reencode-input-port f "ISO_8859-1"))
    (read-line r 'any))

(define (red-server-run)
  (println "Server now listening on stdin")
  (define (loop)
    (let ([line (read-line)])
      (displayln line))
    (loop))
  (loop))

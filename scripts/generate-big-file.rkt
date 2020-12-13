#lang racket/base

(module+ main

  (define (make-line start max-chars)
    (define bs (open-output-bytes))
    (define cnt 0)
    (for ([i (in-naturals start)]
          #:break (> (file-position bs) max-chars))
      (display (format "~a___" i) bs)
      (set! cnt (add1 cnt)))
    (values cnt (get-output-bytes bs)))

  (let loop ([nums 0])
    (when (< nums 10000)
      (let-values ([(cnt line) (make-line nums 200)])
        (write-bytes line)
        (newline)
        (loop (+ nums cnt))))))
      

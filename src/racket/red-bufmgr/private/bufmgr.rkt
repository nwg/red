#lang racket

(require racket/place)
(require racket/vector)
(require red-render)

(provide place-main)

(define global-records #f)

(struct
 line-record
 (info data))

(define (load-file fn)
  (with-input-from-file fn
    (thunk
     (let* ([records
             (sequence-map
              (λ (data)
                (let ([info (get-line-info data)])
                  (line-record info data)))
              (in-lines))]
            [recordsv (list->vector (sequence->list records))])
       (set! global-records recordsv)
       (printf "Loaded ~s lines from ~s\n" (vector-length recordsv) fn))))
  0)


(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define (place-main pch)
  (file-stream-buffer-mode (current-output-port) 'line)
  (file-stream-buffer-mode (current-error-port) 'line)

  (flush-output)
  (let loop ()
    (let* ([exp (place-channel-get pch)]
           [cmd (eval (car exp) ns)]
           [args (cdr exp)])
      (place-channel-put pch (apply cmd args)))
    (loop)))

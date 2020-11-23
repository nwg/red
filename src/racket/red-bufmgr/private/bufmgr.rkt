#lang racket

(require racket/place)
(require racket/vector)
(require racket/os)
(require red-render)
(require ffi/unsafe)

(provide place-main)

(struct portal (id context width height))
(struct buffer (id records))
(struct line-record (info data))
(struct memory (id size addr))

(define buffers (make-hasheqv))
(define portals (make-hasheqv))
(define registered-memory (make-hasheqv))

(define (sequence-generator)
  (let ([nextid 0])
    (λ ()
      (define id nextid)
      (set! nextid (+ 1 nextid))
      id)))

(define get-buffer-id (sequence-generator))
(define get-portal-id (sequence-generator))
(define get-memory-id (sequence-generator))

(define (register-memory addr-uintptr size)
  (let* ([id (get-memory-id)]
         [addr (cast addr-uintptr _uintptr _pointer)]
         [memory (memory id size addr)])
    (hash-set! registered-memory id memory)
    id))

(define (unregister-memory id)
  (let* ([memory (hash-ref registered-memory id)])
    (when (not (eqv? (memory-id memory) id))
      (error "Not registered memory")
      
    (hash-remove! registered-memory id)
    0)))

(define (open-portal shmid width height)
  (let* ([id (get-portal-id)]
         [memory (hash-ref registered-memory shmid)]
         [addr (memory-addr memory)]
         [context (render-context-create addr width height)]
         [portal (portal id context width height)])
    (hash-set! portals id portal)
    id))

(define (close-portal pid)
  (let ([portal (hash-ref portals pid)]
        [context (portal-context portal)])
    (render-context-destroy context)
    (hash-remove! portals pid)
    0))

;; (define (draw-buffer-in-portal bufid pid)
;;   (let* ([buffer (hash-ref buffers bufid)]
;;          [records (buffer-records buffer)]
;;          [portal (hash-ref portals pid)]
;;          [context (portal-context portal)]
;;          [total-height (portal-height portal)])
;;     (define y total-height)
;;     (for ([record records])
;;       (let* ([info (line-record-info record)]
;;              [line-height (+ (lineInfo-ascent info) (lineInfo-descent info))]
;;              [leading (lineInfo-leading info)])
;;         (set! y (- y line-height))
;;         (render-draw-line-in-context context (point leading y) info)))
;;     0))


;; (define (load-file fn)
;;   (with-input-from-file fn
;;     (thunk
;;      (let* ([records
;;              (sequence-map
;;               (λ (data)
;;                 (let ([info (get-line-info data)])
;;                   (line-record info data)))
;;               (in-lines))]
;;             [recordsv (list->vector (sequence->list records))]
;;             [id (get-buffer-id)]
;;             [buf (buffer id recordsv)])
;;        (hash-set! buffers id buf)
;;        (printf "Loaded ~s lines from ~s\n" (vector-length recordsv) fn)
;;        id))))

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
      (place-channel-put pch (apply cmd args))
      (printf "Finished command ~s\n" cmd))
    (loop)))

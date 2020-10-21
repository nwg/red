#lang racket

(require racket/place)
(require racket/vector)
(require racket/os)
(require red-render)
(require "ffi.rkt")

(provide place-main)

(struct portal (id buffer memory width height))
(struct buffer (id records portals))
(struct line-record (info data))
(struct shared-memory (id size addr))

(define buffers (make-hasheqv))
(define portals (make-hasheqv))
(define attached-shared-memory (make-hasheqv))

(define (sequence-generator)
  (let ([nextid 0])
    (λ ()
      (define id nextid)
      (set! nextid (+ 1 nextid))
      id)))

(define get-buffer-id (sequence-generator))
(define get-portal-id (sequence-generator))
(define get-shared-memory-id (sequence-generator))

(define (attach-shared-memory path size)
  (printf "Attaching shared memory ~s with size ~s\n" path size)
  ;; (flush-output)
  (let* ([id (get-shared-memory-id)]
         [fd (shm_open path #x02 #x0)])
    (let* ([addr (mmap #f size #x3 #x1 fd 0)]
           [memory (shared-memory id size addr)])
      (close fd)
      (hash-set! attached-shared-memory id memory)
      id)))

(define (detach-shared-memory id)
  (let* ([memory (hash-ref attached-shared-memory id)]
         [addr (shared-memory-addr memory)]
         [size (shared-memory-size memory)])
    (printf "unmapping\n")
    (munmap addr size)
    (hash-remove! attached-shared-memory id)
    0))

(define (open-portal bufid shmid width height)
  (let* ([id (get-portal-id)]
         [buffer (hash-ref buffers bufid)]
         [memory (hash-ref attached-shared-memory shmid)]
         [portal (portal id buffer memory width height)])
    (hash-set! portals id portal)
    id))

(define (close-portal pid)
  (hash-remove! portals pid)
  0)

(define (load-file fn)
  (with-input-from-file fn
    (thunk
     (let* ([records
             (sequence-map
              (λ (data)
                (let ([info (get-line-info data)])
                  (line-record info data)))
              (in-lines))]
            [recordsv (list->vector (sequence->list records))]
            [id (get-buffer-id)]
            [buf (buffer id recordsv (make-hasheqv))])
       (hash-set! buffers id buf)
       (printf "Loaded ~s lines from ~s\n" (vector-length recordsv) fn)
       id))))

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

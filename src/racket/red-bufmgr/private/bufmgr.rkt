#lang racket

(require racket/place)
(require racket/vector)
(require racket/os)
;(require red-render)
(require ffi/unsafe)
(require tile-matrix)

(provide place-main)

(struct portal (id bufid width height tile-matrix [bounds #:mutable]))
(struct buffer (id [records #:mutable] [height #:mutable]))
(struct line-record (line-id data))
(struct memory (id size addr))

(define buffers (make-hasheqv))
(define portals (make-hasheqv))
(define registered-memory (make-hasheqv))

(define render-place (box #f))

(define (sequence-generator)
  (let ([nextid 0])
    (λ ()
      (define id nextid)
      (set! nextid (+ 1 nextid))
      id)))

(define get-buffer-id (sequence-generator))
(define get-portal-id (sequence-generator))
(define get-memory-id (sequence-generator))

(define (bufmgr-init render-pch)
  (set-box! render-place render-pch)
  0)

(define (render-call msg)
  (place-channel-put (unbox render-place) msg)
  (place-channel-get (unbox render-place)))

(define (open-portal bufid width height)
  (let* ([id (get-portal-id)]
         [matrix (create-render-matrix bufid width height 3 3)]
         [portal (portal id bufid width height matrix #f)])
    (hash-set! portals id portal)
    id))

(define (close-portal pid)
  (let* ([portal (hash-ref portals pid)]
         [m (portal-tile-matrix portal)])
    (destroy-render-matrix m)
    (hash-remove! portals pid)
    0))

(define (create-render-matrix bufid width height rows cols)
  (let* ([m (new tile-matrix% [rows rows] [cols cols] [tile-size (size width height)])])
    (set-field! tile-needs-draw-callback m tile-needs-draw)
    (for ([tile (send m get-all-tiles)])
      (let ([cid (render-call `(render-context-create ,width ,height))])
        (send tile set-attribute! 'cid cid)))
    (send m set-attribute! 'bufid bufid)
    m))

(define (destroy-render-matrix m)
  (for ([tile (send m get-all-tiles)])
    (let ([cid (send tile get-attribute 'cid)])
      (render-call `(render-context-destroy ,cid)))))

(define (tile-needs-draw m tile)
  (send tile set-attribute! 'dirty #t)
  (let* ([pos (get-field pos tile)]
         [bnds (get-field bnds tile)]
         [origin (bounds-origin bnds)]
         [x-start (point-x origin)]
         [y-start (point-y origin)]
         [extents (bounds-extents bnds)]
         [tile-height (size-height extents)])

      (let* ([cid (send tile get-attribute 'cid)]
             [bufid (send m get-attribute 'bufid)]
             [buffer (hash-ref buffers bufid)]
             [records (buffer-records buffer)]
             [total-height (buffer-height buffer)]
             [empty-line-height (render-call `(render-get-empty-line-height))])
        (define y 0)
        (for ([record records])
          (if record
              (let* ([lid (line-record-line-id record)]
                     [line-height (record-height record)])
                (set! y (+ y line-height))
                (render-call `(render-draw-line-in-context ,cid ,lid ,(- x-start) ,(- y y-start)))
                )

              (begin
                (set! y (+ y empty-line-height)))))
        0)))
  
(define (make-2d-vector rows cols)
  (for/vector ([i rows])
    (make-vector cols)))

(define (vector-set-2d! vv i j val)
  (let ([col (vector-ref vv i)])
    (vector-set! col j val)))

(define (get-render-info portalid)
  (let* ([portal (hash-ref portals portalid)]
         [m (portal-tile-matrix portal)]
         [rows (get-field rows m)]
         [cols (get-field cols m)]
         [info-matrix (make-2d-vector rows cols)])
    (for ([tile (send m get-all-tiles)])
      (let* ([pos (get-field pos tile)]
             [i (position-i pos)]
             [j (position-j pos)]
             [bnds (get-field bnds tile)]
             [pt (bounds-origin bnds)]
             [x (point-x pt)]
             [y (point-y pt)]
             [sz (bounds-extents bnds)]
             [w (size-width sz)]
             [h (size-height sz)]
             [cid (send tile get-attribute 'cid)]
             [data (render-call `(render-context-get-data ,cid))]
             [data-ptr (cast data _pointer _uint64)]
             [bnds (get-field bnds tile)]
             [v (vector data-ptr i j x y w h)])
        (vector-set-2d! info-matrix i j v)))
    info-matrix))

(define (create-buffer)
  (let* ([id (get-buffer-id)]
         [buffer (buffer id '() #f)])
    (hash-set! buffers id buffer)
    id))

(define (record-height record)
  (let ([result (render-call `(render-get-line-height ,(line-record-line-id record)))])
    result))

(define (total-height records)
  (let* ([empty-line-height (render-call `(render-get-empty-line-height))]
         [fs (for/sum ([r records]
                       #:when (false? r))
               empty-line-height)]
         [lids (for/list ([r records]
                          #:when r)
                 (line-record-line-id r))])
    (render-call `(render-get-total-line-height ,lids))))

(define (load-records-from-file fn)
  (with-input-from-file fn
    (λ ()
      (for/vector ([data (in-lines)])
        (if (> (string-length data) 0)
            (let ([lid (render-call `(render-get-line-info ,data))])
              (line-record lid data))
            #f)))))

(define (buffer-open-file bufid fn)
  (let* ([buffer (hash-ref buffers bufid)]
         [recordsv (load-records-from-file fn)]
         [height (total-height recordsv)])
    (set-buffer-records! buffer recordsv)
    (set-buffer-height! buffer height)
    0))

(define (set-current-bounds portalid x y w h)
  (let* ([p (hash-ref portals portalid)]
        [m (portal-tile-matrix p)])
    (set-portal-bounds! p (bounds (point x y) (size w h)))
    (send m reload-data)
    0))

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define (place-main pch)
  (let loop ()
    (let* ([exp (place-channel-get pch)]
           [cmd (eval (car exp) ns)]
           [args (cdr exp)])
      (place-channel-put pch (apply cmd args)))
    (loop)))

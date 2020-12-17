#lang racket

(require racket/place)
(require racket/vector)
(require racket/os)
;(require red-render)
(require ffi/unsafe)
(require tile-matrix)
(require red-render)

(provide place-main)

(struct portal (id bufid width height tile-matrix [bounds #:mutable]))
(struct buffer (id [records #:mutable] [height #:mutable]))
(struct line-record (line-id data [position #:mutable] [info #:mutable] [height #:mutable]))
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
           [all-records (buffer-records buffer)]
           [visible-records (records-in-range all-records y-start (+ y-start tile-height))]
           [total-height (buffer-height buffer)]
           [empty-line-height (get-empty-line-height)])
      (for ([record visible-records])
        (when (line-record-line-id record)
          (let* ([lid (line-record-line-id record)]
                 [line-info (line-record-info record)]
                 [line-height (render-line-info-height line-info)]
                 [position (line-record-position record)]
                 [line-y (+ position line-height)])
            ;; (set! y (+ y line-height))
            (printf "Position is ~a\n" position)
            (printf "Ascent is ~a\n" (render-line-info-ascent line-info))
            (printf "Descent is ~a\n" (render-line-info-descent line-info))
            (render-call `(render-draw-line-in-context ,cid ,lid ,(- x-start) ,(- line-y y-start (render-line-info-descent line-info))))
            ;; (render-call `(render-draw-line-in-context ,cid ,lid ,(- x-start) ,(- line-y y-start)))
            )))

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

(define (total-height records)
  (for/sum ([r records])
    (line-record-height r)))

(define (load-records-from-file fn)
  (with-input-from-file fn
    (λ ()
      (for/vector ([data (in-lines)])
        (if (> (string-length data) 0)
            (let ([lid (render-call `(render-create-line ,data))])
              (line-record lid data #f #f #f))
            (line-record #f #f #f #f #f))))))

(define (histogram lst [key identity])
  (reverse
   (foldr
    (λ (v i)
      (let ([v (car i)]
            [vv (key v)])
        (cons (+ v vv) i)))
    (list 0)
    lst)))

(define (get-empty-line-height)
  (let ([info (render-call `(render-get-font-info))])
    (+
     (render-font-info-ascent info)
     (render-font-info-descent info)
     (render-font-info-leading info))))

(define (set-positions-on-records! records)
  (let* ([lids (map (λ (v) (if (line-record-line-id v) (line-record-line-id v) #f)) (vector->list records))]
         [infos (render-call `(render-get-line-infos ,lids))]
         [empty-height (get-empty-line-height)])
    (define (height info)
      (if info
          (render-line-info-height info)
          empty-height))
    (let ([heights (map height infos)])
      (for ([r records]
            [position (histogram heights)]
            [info infos]
            [height heights])

        (set-line-record-height! r height)
        (set-line-record-position! r position)
        (set-line-record-info! r info)))))
  
(define (binary-search v of)
  (define (work start-i end-i)
    (if (>= start-i end-i)
        #f
        (let* ([i (floor (/ (+ start-i end-i) 2))]
               [o (of i)])
          (cond
            [(eq? o '<) (work 0 i)]
            [(eq? o '>) (work (add1 i) end-i)]
            [(eq? o '=) i]
            [else (error "Bad result from search fn:" o)]))))

  (let ([len (vector-length v)])
    (work 0 len)))

(define (records-in-range records start-y end-y)
  (define (search-start i)
    (let* ([r (vector-ref records i)]
           [pos (line-record-position r)]
           [info (line-record-info r)]
           [height (line-record-height r)])
      (cond
        [(or
          (= pos start-y)
          (and (< pos start-y) (> (+ pos height) start-y)))
         '=]
        [(< start-y pos) '<]
        [else '>])))

  (define (search-end i)
    (let* ([r (vector-ref records i)]
           [pos (line-record-position r)]
           [info (line-record-info r)]
           [height (render-line-info-height info)])
      (cond
        [(or
          (= (+ pos height) end-y)
          (and (< pos end-y) (> (+ pos height) end-y)))
         ;; (printf "pos=~a height=~a end-y=~a => '=\n" pos height end-y)
         '=]
        [(< end-y pos)
         ;; (printf "pos=~a height=~a end-y=~a => '<\n" pos height end-y)
         '<]
        [else
         ;; (printf "pos=~a height=~a end-y=~a => '>\n" pos height end-y)
         '>])))
    

  (let ([i-start (binary-search records search-start)]
        [i-end (binary-search records search-end)])
    (if (not (and i-start i-end))
        (error "Could not find start and end for" start-y end-y)
        (begin
          ;; (printf "Found i-start=~a i-end=~a\n" i-start i-end)
          (vector-copy records i-start (add1 i-end))))))
  
(define (buffer-open-file bufid fn)
  (let* ([buffer (hash-ref buffers bufid)]
         [recordsv (load-records-from-file fn)])
    (set-positions-on-records! recordsv)
    (set-buffer-records! buffer recordsv)

    (let ([height (total-height recordsv)])
      (set-buffer-height! buffer height))
    
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

#lang racket

(require racket/place)
(require racket/vector)
(require racket/os)
;(require red-render)
(require ffi/unsafe)
(require tile-matrix)
(require red-render)
(require (only-in srfi/43 vector-fold))

(provide place-main)

(struct portal (id bufid width height tile-matrix [bounds #:mutable]))
(struct buffer (id [records #:mutable] [width #:mutable] [height #:mutable]))
(struct line-record (line-id data [position #:mutable] [info #:mutable] [height #:mutable]))
(struct memory (id size addr))

(define buffers (make-hasheqv))
(define portals (make-hasheqv))
(define registered-memory (make-hasheqv))

(define render-place #f)
(define client-place #f)
(define callback-place #f)

(define (sequence-generator)
  (let ([nextid 0])
    (λ ()
      (define id nextid)
      (set! nextid (+ 1 nextid))
      id)))

(define get-buffer-id (sequence-generator))
(define get-portal-id (sequence-generator))
(define get-memory-id (sequence-generator))

(define portal-num-rows 3)
(define portal-num-cols 3)
  

(define (render-call msg)
  (place-channel-put render-place msg)
  (place-channel-get render-place))

(define (callback-call msg)
  (place-channel-put callback-place msg)
  (place-channel-get callback-place))

(define (open-portal bufid width height)
  (let* ([id (get-portal-id)]
         [buffer (hash-ref buffers bufid)]
         [total-width (buffer-width buffer)]
         [total-height (buffer-height buffer)]
         [matrix (create-render-matrix bufid width height total-width total-height portal-num-rows portal-num-cols)]
         [portal (portal id bufid width height matrix #f)])
    (send matrix set-attribute! 'portalid id)
    (hash-set! portals id portal)
    id))

(define (close-portal pid)
  (let* ([portal (hash-ref portals pid)]
         [m (portal-tile-matrix portal)])
    (destroy-render-matrix m)
    (hash-remove! portals pid)
    0))

(define (create-render-matrix bufid tile-width tile-height total-width total-height rows cols)
  (let* ([m (new tile-matrix% [rows rows] [cols cols] [total-size (size total-width total-height)] [tile-size (size tile-width tile-height)])])
    (set-field! tile-needs-draw-callback m tile-needs-draw)
    (set-field! tile-did-move-callback m tile-did-move)
    (for ([tile (send m get-all-tiles)])
      (let ([cid (render-call `(render-context-create ,tile-width ,tile-height))])
        (send tile set-attribute! 'cid cid)))
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
         [tile-width (size-width extents)]
         [tile-height (size-height extents)])

    (let* ([cid (send tile get-attribute 'cid)]
           [portalid (send m get-attribute 'portalid)]
           [portal (hash-ref portals portalid)]
           [bufid (portal-bufid portal)]
           [buffer (hash-ref buffers bufid)]
           [all-records (buffer-records buffer)]
           [visible-records (records-in-range all-records y-start (+ y-start tile-height))]
           [total-height (buffer-height buffer)])
      (when (= (vector-length visible-records) 0)
        (printf "Warning -- no visisble records for tile at ~a/~a\n" x-start y-start))
      (render-call `(render-clear-rect ,cid 0 0 ,tile-width ,tile-height))
      (for ([record visible-records])
        (when (line-record-line-id record)
          (let* ([lid (line-record-line-id record)]
                 [line-info (line-record-info record)]
                 [line-height (render-line-info-height line-info)]
                 [position (line-record-position record)]
                 [ascent (render-line-info-ascent line-info)]
                 [line-y (+ position ascent)]
                 [data (line-record-data record)])

            (render-call `(render-draw-line-in-context ,cid ,lid ,(- x-start) ,(- line-y y-start)))
            )))

      (let* ([pos-info (get-callback-tile-info tile)])
        (callback-call `(tile-did-change ,pos-info)))

      0)))

(define (tile-did-move m old-pos tile)
  (let* ([pos-info (get-callback-tile-info tile)]
         [old-i (position-i old-pos)]
         [old-j (position-j old-pos)])
    (callback-call `(tile-did-move ,old-i ,old-j ,pos-info))))
  
(define (make-2d-vector rows cols)
  (for/vector ([i rows])
    (make-vector cols)))

(define (vector-set-2d! vv i j val)
  (let ([col (vector-ref vv i)])
    (vector-set! col j val)))

(define (get-callback-tile-info tile)
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
         [v (vector data-ptr i j x y w h)])
    v))

(define (get-render-info portalid)
  (let* ([portal (hash-ref portals portalid)]
         [bufid (portal-bufid portal)]
         [buffer (hash-ref buffers bufid)]
         [height (exact-round (buffer-height buffer))]
         [width (exact-round (buffer-width buffer))]
         [m (portal-tile-matrix portal)]
         [rows (send m num-visible-rows)]
         [cols (send m num-visible-cols)])
    (vector rows cols width height)))

(define (create-buffer)
  (let* ([id (get-buffer-id)]
         [buffer (buffer id '() #f #f)])
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

(define (max-width-for-records records)
  (define (find-max i s v)
    (let ([info (line-record-info v)])
      (if info
          (let ([width (render-line-info-width info)])
            (max s width))
          s)))

  (vector-fold find-max -inf.0 records))

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
  (define len (vector-length records))
  
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
          (= i (sub1 len))
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
    

  (let* ([i-start (binary-search records search-start)]
         [i-end (binary-search records search-end)])
    (if (not i-start)
        (begin
          (printf "Could not find start and end for ~a ~a ~a ~a\n" start-y end-y i-start i-end)
          (vector))        
        (let ([start-record (vector-ref records i-start)]
              [end-record (vector-ref records i-end)])
          (vector-copy records i-start (add1 i-end))))))
  
(define (buffer-open-file bufid fn)
  (let* ([buffer (hash-ref buffers bufid)]
         [recordsv (load-records-from-file fn)])
    (set-positions-on-records! recordsv)
    (set-buffer-records! buffer recordsv)

    (let ([height (total-height recordsv)])
      (set-buffer-height! buffer height))
    (let ([width (max-width-for-records recordsv)])
      (set-buffer-width! buffer width))
    
    0))

(define (set-current-bounds portalid x y w h)
  (let* ([p (hash-ref portals portalid)]
         [m (portal-tile-matrix p)]
         [bnds (bounds (point x y) (size w h))])
    (set-portal-bounds! p bnds)
    (thread
     (λ ()
       (send m move-viewport bnds)))
    0))

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define (place-main pch)
  (set! render-place (place-channel-get pch))
  (set! client-place (place-channel-get pch))
  (set! callback-place pch)

  (place-channel-put pch 'ok)
  
  (let loop ()
    (let* ([exp (place-channel-get client-place)]
           [cmd (eval (car exp) ns)]
           [args (cdr exp)])
      (place-channel-put client-place (apply cmd args)))
    (loop)))

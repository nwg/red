#lang racket/base

(require racket/class)
(require data/queue)
(require racket/generator)
(require lens)
(require racket/function)

(struct/lens position (i j) #:transparent)
(struct/lens point (x y) #:transparent)
(struct/lens size (width height) #:transparent)
(struct/lens bounds (origin extents) #:transparent)
(struct/lens tile (position bounds dirty))

(define ((tile-set-dirty d) t)
  (lens-transform tile-dirty-lens t (const d)))

(define (point-add p x y)
  (point (+ (point-x p) x) (+ (point-y p) y)))

(define (point-average p1 p2)
  (point
   (floor (/ (+ (point-x p1) (point-x p2)) 2))
   (floor (/ (+ (point-y p1) (point-y p2)) 2))))

(define (bounds-center b)
  (let* ([p1 (bounds-origin b)]
         [e1 (bounds-extents b)]
         [p2 (point-add p1 (size-width e1) (size-height e1))]
         [avg (point-average p1 p2)])
    avg))

(define (position-add p1 p2)
  (let ([ni (+ (position-i p1) (position-i p2))]
        [nj (+ (position-j p1) (position-j p2))])
    (position ni nj)))

(define (negate-position p)
  (position (- (position-i p)) (- (position-j p))))

(define (position-subtract p1 p2)
  (position-add p1 (negate-position p2)))

(define tile-matrix%
  (class object%
    (super-new)
    (init rows cols tile-size)

    (field [tile-did-change-callback #f])

    (define/public (move-viewport new-bounds)
      (internal-move-viewport new-bounds))

    (define current-viewport (bounds (point 0 0) tile-size))
    
    (define (min-position center)
      (position-subtract center (position (floor (/ rows 2)) (floor (/ cols 2)))))

    (define (max-position center)
      (position-add center (position (floor (/ rows 2)) (floor (/ cols 2)))))

    (define (local-position p center)
      (let* ([minpos (min-position center)])
        (position-subtract p minpos)))

    (define (global-position p center)
      (let* ([minpos (min-position center)])
        (position-add p minpos)))

    (define (get-tile pos)
      (vector-ref (vector-ref the-tiles (position-i pos)) (position-j pos)))

    (define (set-tile! pos tile)
      (vector-set! (vector-ref the-tiles (position-i pos)) (position-j pos) tile))

    (define (all-positions)
      (for*/list ([i rows]
                  [j cols])
        (position i j)))
    
    (define (tile-transform! pos f)
      (let* ([t (get-tile pos)]
             [transformed (f t)])
        (set-tile! pos transformed)))
    
    (define (clear-dirty pos)
      (tile-transform! pos (tile-set-dirty #f)))

    (define (bounds-for-position p)
      (let* ([width (size-width tile-size)]
             [height (size-height tile-size)]
             [start-x (* (position-j p) width)]
             [start-y (* (position-i p) height)])
        (bounds (point start-x start-y) tile-size)))

    (define (get-center-position viewport)
      (let* ([center (bounds-center viewport)]
             [tile-i (floor (/ (point-y center) (size-height tile-size)))]
             [tile-j (floor (/ (point-x center) (size-width tile-size)))]
             [min-i (floor (/ (sub1 rows) 2))]
             [min-j (floor (/ (sub1 cols) 2))])
        (position (max min-i tile-i) (max min-i tile-j))))

    (define (tiles-passing-test f)
      (in-generator
       (for* ([i (in-range rows)]
              [j (in-range cols)])
         
         (let* ([pos (position i j)]
                [tile (get-tile pos)])
           (when (f tile pos)
             (yield tile))))))
    
    (define current-center (get-center-position current-viewport))

    (define the-tiles (for/vector ([i rows])
                        (for/vector ([j cols])
                          (let ([bnds (bounds-for-position (position i j))])
                            (tile (position i j) bnds #f)))))

    (define (internal-move-viewport new-bounds)
      (set! current-viewport new-bounds)
      (let ([new-center (get-center-position new-bounds)])
        (when (not (equal? current-center new-center))
          (let ([old-center current-center])
            (set! current-center new-center)
            (let* ([dpos (position-subtract new-center old-center)]
                   [di (position-i dpos)]
                   [dj (position-j dpos)]
                   [max-pos (max-position old-center)]
                   [max-i (position-i max-pos)]
                   [max-j (position-j max-pos)]
                   [min-pos (min-position old-center)]
                   [min-i (position-i min-pos)]
                   [min-j (position-j min-pos)]
                   [start-i-preserved (if (< di 0) (- di) 0)]
                   [end-i-preserved (if (< di 0) rows (- rows di))]
                   [start-j-preserved (if (< dj 0) (- dj) 0)]
                   [end-j-preserved (if (< dj 0) cols (- cols dj))])

              (define (preserved-tile-test tile pos)
                (and
                 (<= start-i-preserved (position-i pos) (sub1 end-i-preserved))
                 (<= start-j-preserved (position-j pos) (sub1 end-j-preserved))))

              (define (invert f)
                (lambda args
                  (not (apply f args))))

              (define dirty-tile-test (invert preserved-tile-test))

              (for ([preserved-tile (tiles-passing-test preserved-tile-test)])
                (let* ([new-local-pos (tile-position preserved-tile)]
                       [new-global-pos (global-position new-local-pos new-center)]
                       [old-local-pos (position-add new-local-pos dpos)]
                       [new-bnds (bounds-for-position new-global-pos)]
                       [old-tile (get-tile old-local-pos)]
                       [new-tile (tile new-local-pos new-bnds (tile-dirty old-tile))])                  
                  (when tile-did-change-callback
                    (tile-did-change-callback old-tile new-tile))
                  (set-tile! new-local-pos new-tile)))

              (for ([old-tile (tiles-passing-test dirty-tile-test)])
                (let* ([local-pos (tile-position old-tile)]
                       [new-global-pos (global-position local-pos new-center)]
                       [new-bnds (bounds-for-position new-global-pos)]
                       [new-tile (tile local-pos new-bnds #t)])
                  (when tile-did-change-callback
                    (tile-did-change-callback old-tile new-tile))
                  (set-tile! local-pos new-tile))))))))

    (define/public (clear-all-dirty)
      (for ([pos (all-positions)])
        (clear-dirty pos)))))
              
                      
        
      
(module+ test
  (define (change old-tile new-tile)
    (if (tile-dirty new-tile)
        (printf "Tile ~a -> ~a (bounds=~a) is dirty.\n" (tile-position old-tile) (tile-position new-tile) (tile-bounds new-tile))
        (printf "Tile ~a -> ~a (bounds=~a) is not dirty\n" (tile-position old-tile) (tile-position new-tile) (tile-bounds new-tile))))

  (define m (new tile-matrix% [rows 5] [cols 5] [tile-size (size 800 600)]))
  (set-field! tile-did-change-callback m change)
  
  (send m move-viewport (bounds (point (+ (* 800 8) 400) (+ (* 600 8) 300)) (size 800 600)))
  (send m clear-all-dirty)
  (send m move-viewport (bounds (point (+ (* 800 4) 400) (+ (* 600 4) 300)) (size 800 600)))
 (send m clear-all-dirty)
  (send m move-viewport (bounds (point (+ (* 800 2) 400) (+ (* 600 2) 300)) (size 800 600)))
  )

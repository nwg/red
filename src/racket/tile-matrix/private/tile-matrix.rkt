#lang racket/base

(require racket/class)
(require racket/generator)
(require racket/function)
(require racket/vector)
(require racket/math)
(require "data.rkt")
(require racket/set)

(provide tile-matrix%)

(define tile-matrix%
  (class object%
    (super-new)
    (init-field rows cols total-size tile-size)

    (field [tile-did-move-callback #f])
    (field [tile-needs-draw-callback #f])
    (field [tile-was-deleted-callback #f])

    (set! total-size (size (exact-ceiling (size-width total-size)) (exact-ceiling (size-height total-size))))
    
    (define current-viewport #f)
    
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

    (define/public (num-visible-rows)
      (min rows (add1 (floor (/ (size-height total-size) (size-height tile-size))))))

    (define/public (num-visible-cols)
      (min cols (add1 (floor (/ (size-width total-size) (size-width tile-size))))))
    
    (define (origin-for-position p)
      (point (* (size-width tile-size) (position-j p))
             (* (size-height tile-size) (position-i p))))
    
    (define (position-visible p)
      (let ([o (origin-for-position p)])
        (and (< (point-x o) (size-width total-size))
             (< (point-y o) (size-height total-size)))))
      
    (define (all-positions)
      (for*/list ([i rows]
                  [j cols])
        (position i j)))

    (define (all-visible-positions)
      (for/list ([p (all-positions)]
                 #:when (position-visible p))
        p))

    (define (all-tiles)
      (apply vector-append (vector->list the-tiles)))
    
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
             [rows-from-center (floor (/ rows 2))]
             [cols-from-center (floor (/ cols 2))]
             [min-i rows-from-center]
             [min-j cols-from-center]
             [max-i (max min-i (- (floor (/ (size-height total-size) (size-height tile-size))) rows-from-center))]
             [max-j (max min-j (- (floor (/ (size-width total-size) (size-width tile-size))) cols-from-center))]
             [pos (position (min (max min-i tile-i) max-i) (min (max min-j tile-j) max-j))])

        pos))

    (define (visible-positions-passing-test f)
      (in-generator
       (for ([pos (all-visible-positions)])
         (when (f pos)
           (yield pos)))))
    
    (define current-center #f)

    (define the-tiles (for/vector ([i rows])
                        (for/vector ([j cols])
                          (let ([bnds (bounds-for-position (position i j))])
                            (new tile% [pos (position i j)] [bnds bnds])))))

        
    (define (internal-move-viewport self new-bounds)
      (define (redraw-tiles positions)
        (for ([local-pos positions])
          (let* ([new-global-pos (global-position local-pos current-center)]
                 [new-bnds (bounds-for-position new-global-pos)]
                 [tile (get-tile local-pos)])
            (set-field! pos tile local-pos)
            (set-field! bnds tile new-bnds)
            (when tile-needs-draw-callback
              (tile-needs-draw-callback self tile)))))
      
      (if (not current-viewport)
          (begin
            (set! current-viewport new-bounds)
            (set! current-center (get-center-position new-bounds))
            (redraw-tiles (all-visible-positions)))
              

          (begin
            
            (set! current-viewport new-bounds)
            (let ([new-center (get-center-position new-bounds)])
              (when (not (equal? current-center new-center))
                (let ([old-center current-center])
                  (set! current-center new-center)
                  (let* ([deleted-positions (list->mutable-set (all-visible-positions))]
                         [dpos (position-subtract new-center old-center)]
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

                    (define (preserved-pos-test pos)
                      (and
                       (<= start-i-preserved (position-i pos) (sub1 end-i-preserved))
                       (<= start-j-preserved (position-j pos) (sub1 end-j-preserved))))

                    (define (invert f)
                      (lambda args
                        (not (apply f args))))

                    (define dirty-pos-test (invert preserved-pos-test))


                    (define moves (mutable-set))
                    (for ([new-local-pos (visible-positions-passing-test preserved-pos-test)])
                      (let* ([new-global-pos (global-position new-local-pos new-center)]
                             [old-local-pos (position-add new-local-pos dpos)]
                             [new-bnds (bounds-for-position new-global-pos)]
                             [tile (get-tile old-local-pos)]
                             [swap-tile (get-tile new-local-pos)])
                        (set-field! bnds tile new-bnds)
                        (set-field! pos tile new-local-pos)
                        (set-tile! new-local-pos tile)
                        (set-tile! old-local-pos swap-tile)
                        (set-add! moves (vector old-local-pos new-local-pos))))

                    (when tile-was-deleted-callback
                      (let* ([preserved (for/set ([pos (visible-positions-passing-test preserved-pos-test)])
                                          (let ([old-local-pos (position-add pos dpos)])
                                            old-local-pos))]
                             [all-positions (list->set (all-visible-positions))]
                             [deleted-positions (set-subtract all-positions preserved)])
                        
                        (for ([pos deleted-positions])
                          (tile-was-deleted-callback self (get-tile pos)))))
                    
                    (when tile-did-move-callback
                      (tile-did-move-callback self moves))




                    (redraw-tiles (visible-positions-passing-test dirty-pos-test)))))))))
    
    (define/public (move-viewport new-bounds)
      (internal-move-viewport this new-bounds))

    (define/public (get-all-tiles)
      (all-tiles))

    (define/public (reload-data)
      (when tile-needs-draw-callback
        (for ([tile (all-tiles)])
          (tile-needs-draw-callback this tile))))
    
    (define attributes (make-hasheq))

    (define/public (set-attribute! attr value)
      (hash-set! attributes attr value))

    (define/public (get-attribute attr)
      (hash-ref attributes attr))

    ))


        



              
                      
        
      
(module+ test
  (define (needs-draw m tile)
    (printf "Tile ~a needs draw\n" (get-field pos tile)))

  (define (did-move m old-pos tile)
    (printf "Tile moved ~a -> ~a\n" old-pos (get-field pos tile)))

  (define m (new tile-matrix% [rows 5] [cols 5] [tile-size (size 800 600)]))
  (set-field! tile-needs-draw-callback m needs-draw)
  (set-field! tile-did-move-callback m did-move)
  
  (send m move-viewport (bounds (point (+ (* 800 8) 400) (+ (* 600 8) 300)) (size 800 600)))
  (send m move-viewport (bounds (point (+ (* 800 4) 400) (+ (* 600 4) 300)) (size 800 600)))
  (send m move-viewport (bounds (point (+ (* 800 2) 400) (+ (* 600 2) 300)) (size 800 600)))
  )

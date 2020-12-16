#lang racket/base

(require racket/class)

(struct position (i j) #:transparent)
(struct point (x y) #:transparent)
(struct size (width height) #:transparent)
(struct bounds (origin extents) #:transparent)

(provide (struct-out position)
         (struct-out point)
         (struct-out size)
         (struct-out bounds)
         point-add
         point-average
         bounds-center
         position-add
         negate-position
         position-subtract
         tile%)

(define tile%
  (class object%
    (super-new)
    (init-field pos bnds)

    ;; (field [pos pos])
    ;; (field [bnds bnds])

    (define attributes (make-hasheq))

    (define/public (set-attribute! attr value)
      (hash-set! attributes attr value))

    (define/public (get-attribute attr)
      (hash-ref attributes attr))))

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


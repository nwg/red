#lang racket/base

(require ffi/unsafe)

(provide callbacks-handle
         callbacks-init)

(define _tileproc
  (_cprocedure (list _racket) _void))

(define tile-did-change-fn #f)

(define (callbacks-init tile-did-change-fp)
  (set! tile-did-change-fn (cast tile-did-change-fp _uintptr _tileproc)))
  
(define (callbacks-handle cmd args)
  (cond
    [(eq? cmd 'tile-did-change) (tile-did-change-fn args)]
    [else (error "Unknown cmd" cmd)]))

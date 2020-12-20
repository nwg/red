#lang racket/base

(require ffi/unsafe)

(provide callbacks-handle
         callbacks-init)

(define _tileproc
  (_cprocedure (list _racket) _void))

(define _tilemoveproc
  (_cprocedure (list _uint _uint _racket) _void))

(define tile-did-change-fn #f)
(define tile-did-move-fn #f)

(define (callbacks-init tile-did-change-fp tile-did-move-fp)
  (set! tile-did-change-fn (cast tile-did-change-fp _uintptr _tileproc))
  (set! tile-did-move-fn (cast tile-did-move-fp _uintptr _tilemoveproc)))
  
(define (callbacks-handle cmd args)
  (cond
    [(eq? cmd 'tile-did-change) (apply tile-did-change-fn args)]
    [(eq? cmd 'tile-did-move) (apply tile-did-move-fn args)]
    [else (error "Unknown cmd" cmd)]))

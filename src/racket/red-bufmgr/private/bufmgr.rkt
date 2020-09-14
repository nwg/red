#lang racket/base

(require racket/place)

(define bufmgr-cmds
  "blah")
  
(define (run-bufmgr ch)
  (let main
      ([cmd (place-channel-get ch)])
    (when (memq (car cmd) bufmgr-cmds)
      (apply (car cmd) (cdr cmd)))
    (main)))

(define (blah arg1)
  (printf "~a~n" arg1))


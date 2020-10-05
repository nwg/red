#lang racket/base

(require racket/place)
(require racket/vector)
;; (require vector-struct)

(provide place-main)

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

(define lines (vector))

;; (vecstruct
;;  line-info
;;  (info data))

(define (load-file fn)
  (with-input-from-file
    fn
    (λ ()
      (for ([line (in-lines)])
        (vector-append lines line)))))

(define (place-main pch)
  (let loop ()
    (place-channel-put pch (eval (place-channel-get pch)))
    (loop)))

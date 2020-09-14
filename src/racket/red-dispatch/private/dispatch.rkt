#lang racket

(require zeromq)
(require ffi/unsafe)
(require ffi/unsafe/define)

(provide server-ctx server-init run-server)

(define (server-ctx) (zmq-unsafe-get-ctx))

(define holdon-prevent-gc '())

(define (server-init)
  (let-values ([(ctx holdon) (server-ctx)])
    (set! holdon-prevent-gc holdon)
    ctx))

(define (run-server)

  (define responder (zmq-socket 'rep))

  (zmq-bind responder "inproc://dispatch")

  (let loop ()
    (define msg (zmq-recv-string responder))
    (printf "Server received: ~s\n" msg)

    (zmq-send responder "World")
    (loop)))


#lang racket

(require zeromq)
(require ffi/unsafe)
(require ffi/unsafe/define)
(require msgpack)

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
    (define msg (zmq-recv responder))
    (printf "Server received: ~s\n" (unpack msg))

    (zmq-send responder (pack 0))
    (loop)))


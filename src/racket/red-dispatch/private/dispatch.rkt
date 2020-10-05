#lang racket

(require racket/pretty)
(require zeromq)
(require ffi/unsafe)
(require ffi/unsafe/define)
(require msgpack)

(provide server-ctx server-init run-server)

(define (server-ctx) (zmq-unsafe-get-ctx))

(define holdon-prevent-gc '())
(define responder '())

(define-ffi-definer define-client #f)
(define-client
  server_set_ctx
  (_fun _zmq_ctx-pointer -> _void))

(define (server-init)
  (let-values ([(ctx holdon) (server-ctx)])
    (set! holdon-prevent-gc holdon)
    (set! responder (zmq-socket 'rep))
    (zmq-bind responder "inproc://dispatch")
    (printf "Bound socket -- server initialized\n")
    (server_set_ctx ctx)))

(define (run-server)
  (let loop ()
    (define msg (zmq-recv responder))
    (let-values ([(cmd rest) (unpack/rest msg)])
      (printf "Server received: ~s / ~s\n" cmd (unpack rest)))

    (zmq-send responder (pack 0))
    (loop)))


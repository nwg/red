#lang racket

(require racket/pretty)
(require zeromq)
(require ffi/unsafe)
(require ffi/unsafe/define)
(require msgpack)
(require racket/set)

(provide server-ctx server-init run-server)

(define (server-ctx) (zmq-unsafe-get-ctx))

(define holdon-prevent-gc '())
(define responder '())

(define-ffi-definer define-client #f)
(define-client
  server_set_ctx
  (_fun _zmq_ctx-pointer -> _void))

(define bufmgr-cmds
  (set "load-file"))

(define (server-init)
  (let-values ([(ctx holdon) (server-ctx)])
    (set! holdon-prevent-gc holdon)
    (set! responder (zmq-socket 'rep))
    (zmq-bind responder "inproc://dispatch")
    (printf "Bound socket -- server initialized\n")
    (server_set_ctx ctx)))

(define (run-server)
  (let ([bufmgr (dynamic-place 'red-bufmgr 'place-main)])
    (let loop ()
      (define msg (zmq-recv responder))
      (let-values ([(cmd rest) (unpack/rest msg)])
        (printf "Server received: ~s / ~s\n" cmd (unpack rest))
        (cond
          [(set-member? bufmgr-cmds cmd)
           (place-channel-put bufmgr (cons (string->symbol cmd) (vector->list (unpack rest))))
           (let ([result (place-channel-get bufmgr)])
             (zmq-send responder (pack result)))]
          [else
           (zmq-send responder (pack 0))]))
      (loop))))


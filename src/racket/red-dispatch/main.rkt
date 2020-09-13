#lang racket

(require zeromq)
(require ffi/unsafe)
(require ffi/unsafe/define)

(provide test-server server-ctx responder-thread server-init run-server)

(define-ffi-definer define-client #f)
(define-client
  init_client_from_server
  (_fun _zmq_ctx-pointer -> _void))

(define (server-ctx) (zmq-unsafe-get-ctx))

(define holdon-prevent-gc '())

(define (server-init)
  (let-values ([(ctx holdon) (server-ctx)])
    (set! holdon-prevent-gc holdon)
    (init_client_from_server ctx)))

(define (run-server)
  (define r (responder-thread))
  (thread-wait r))

(define (responder-thread)
  (thread
   (λ ()
     (define responder (zmq-socket 'rep))
     (zmq-bind responder "inproc://dispatch")
     (let loop ()
       (define msg (zmq-recv-string responder))
       (printf "Server received: ~s\n" msg)
       (zmq-send responder "World")
       (loop)))))

(define (test-server)
  (define requester (zmq-socket 'req #:connect "inproc://dispatch"))
  (for ([request-number (in-range 3)])
    (zmq-send requester "Hello")
    (define response (zmq-recv-string requester))
    (printf "Client received ~s (#~s)\n" response request-number)))



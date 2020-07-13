#lang racket

(require zeromq)

(provide test-server)

(define (test-server)
  (define responder-thread
    (thread
     (λ ()
       (define responder (zmq-socket 'rep))
       (zmq-bind responder "tcp://*:5555")
       (let loop ()
         (define msg (zmq-recv-string responder))
         (printf "Server received: ~s\n" msg)
         (zmq-send responder "World")
         (loop)))))
  (define requester (zmq-socket 'req #:connect "tcp://localhost:5555"))
  (for ([request-number (in-range 3)])
    (zmq-send requester "Hello")
    (define response (zmq-recv-string requester))
    (printf "Client received ~s (#~s)\n" response request-number)))


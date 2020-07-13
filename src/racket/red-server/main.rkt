#lang racket

(require (prefix-in zmq: net/zmq))

(provide test-server)

(define (test-server)
  (let ([ctx (zmq:context 1)])
    (define blah
      (thread
       (λ ()
         (let* ([socket (zmq:socket ctx 'REP)])
           (println "Server now listening on inproc transport")
           (zmq:socket-bind! socket "inproc://here")
           (println "Here")
           (printf "~a\n" (bytes->string/utf-8 (zmq:socket-recv! socket)))
           (println "After")))))
         ;; (println msg)))))
         ;; (printf "Got msg ~a\n" msg)))))
  ;; (define c2
  ;;   (thread
  ;;    (λ ()
  ;;      (let* ([ctx (zmq:context 1)]
  ;;             [socket (zmq:socket ctx 'REQ)])
  ;;        (zmq:socket-send! socket (string->bytes/utf-8 "hello"))))))
    (printf "here\n")
    (let* ([socket (zmq:socket ctx 'REQ)])
      (println "Client")
      (zmq:socket-connect! socket "inproc://here")
      (zmq:socket-send! socket (string->bytes/utf-8 "Some Message")))

    (thread-wait blah)))


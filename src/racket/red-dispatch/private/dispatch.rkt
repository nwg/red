#lang racket

(require racket/pretty)
(require zeromq)
(require ffi/unsafe)
(require ffi/unsafe/define)
(require msgpack)
(require racket/set)

(provide server-init run-server)

(define responder #f)

;; (define-ffi-definer define-client #f)
;; (define-client
;;   server_set_ctx
;;   (_fun _zmq_ctx-pointer -> _void))

(define bufmgr-cmds
  (set "load-file"))

(define (server-init socketfn)
  (printf "Initializing server\n")
  (set! responder (zmq-socket 'rep))
  (let ([fn (format "ipc://~a" socketfn)])
    (zmq-bind responder fn)))

(define (run-server)
  (let ([bufmgr (dynamic-place 'red-bufmgr 'place-main)]
        [closed (zmq-closed-evt responder)])
    
    (let loop ()

      (let ([evt (sync responder (eof-evt (current-input-port)))])
        (match evt
          [(zmq-message frames)             
           (define msg (car frames))
           (let-values ([(cmd rest) (unpack/rest msg)])
             (printf "Server received: ~s / ~s\n" cmd (unpack rest))
             (cond
               [(set-member? bufmgr-cmds cmd)
                (place-channel-put bufmgr (cons (string->symbol cmd) (vector->list (unpack rest))))
                (let ([result (place-channel-get bufmgr)])
                  (zmq-send responder (pack result)))]
               [else
                (zmq-send responder (pack -1))]))
           (loop)]
          [(? eof-object?) '()])))))


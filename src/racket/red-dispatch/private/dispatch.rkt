#lang racket

(require racket/pretty)
(require zeromq)
(require ffi/unsafe)
(require ffi/unsafe/define)
(require msgpack)
(require racket/set)
(require racket/port)

(provide server-init run-server)

(define responder #f)
(define responder-file #f)
(define log-file #f)

;; (define-ffi-definer define-client #f)
;; (define-client
;;   server_set_ctx
;;   (_fun _zmq_ctx-pointer -> _void))

(define bufmgr-cmds
  (set "load-file"))

(define (server-init socketfn)
  (set! log-file (open-output-file "/tmp/red-dispatch.log" #:mode 'text #:exists 'truncate))
  (file-stream-buffer-mode log-file 'line)
  (file-stream-buffer-mode (current-output-port) 'line)
  (file-stream-buffer-mode (current-error-port) 'line)
  (current-output-port (combine-output log-file (current-output-port)))
  (current-error-port (combine-output log-file (current-error-port)))

  (printf "Initializing server\n")
  (set! responder (zmq-socket 'rep))
  (set! responder-file socketfn)
  (printf "Binding socket ~a\n" socketfn)
  (zmq-bind responder (format "ipc://~a" responder-file)))

(define (server-shutdown)
  (current-output-port log-file)
  (current-error-port log-file)
  (printf "Shutting down\n")
  
  (zmq-close responder)
  (delete-file responder-file)  
  (set! responder-file #f)
  (set! responder #f)
  
  (printf "Finished shutting down\n"))

(define (run-server)
  (let ([bufmgr (dynamic-place 'red-bufmgr 'place-main)])
    
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
          [(? eof-object?)
           (server-shutdown)
           '()])))))


#lang racket/base

(require setup/dirs)
(find-system-path 'run-file)
(printf "find-config-dir: ~a\n" (find-config-dir))
(printf "get-lib-search-dirs: ~a\n" (get-lib-search-dirs))
(printf "find-pkgs-dir: ~a\n" (find-pkgs-dir))
(printf "get-pkgs-search-dirs: ~a\n" (get-pkgs-search-dirs))
(printf "find-share ~a\n" (find-share-dir))
(printf "find-collects-dir ~a\n" (find-collects-dir))
(printf "current-library-collection-paths ~a\n" (current-library-collection-paths))
(printf "current-library-collection-links ~a\n" (current-library-collection-links))
(current-command-line-arguments)
;(require (prefix-in zmq: net/zmq))
;(require red-server)
;(define test-server (dynamic-require 'red-server 'test-server))
;(test-server)

(define socket (dynamic-require 'zeromq 'zmq-socket))
(define ctx (dynamic-require 'net/zmq 'context))

;(let ([run (dynamic-require 'red-server 'red-server-run)])
; (run))

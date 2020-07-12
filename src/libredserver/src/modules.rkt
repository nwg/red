#lang racket/base

;(require red-server)
(let ([run (dynamic-require 'red-server 'red-server-run)])
 (run))

(displayln "Hello")
;(red-server-run)

#lang racket/base

;; (provide get-line-info)

(require "load-ffi.rkt")
(provide get-line-info)


(render-reload "libred-render-core-text")

((render-get-func 'red_render_init))

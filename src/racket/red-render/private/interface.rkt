#lang racket/base

;; (provide get-line-info)

(require "load-ffi.rkt")


(render-reload "libred-render-something-else")
(render-reload "libred-render-core-text")

((get-func 'red_render_init))
(get-line-height "something Here")

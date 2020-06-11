#lang racket/gui

(define f (new frame% [label "Simple Edit"]
                      [width 200]
                      [height 200]))
(define c (new editor-canvas% [parent f]))
(define t (new text%))
(send c set-editor t)
(send f show #t)

(define mb (new menu-bar% [parent f]))
(define m-edit (new menu% [label "Edit"] [parent mb]))
(define m-font (new menu% [label "Font"] [parent mb]))
(append-editor-operation-menu-items m-edit #f)
(append-editor-font-menu-items m-font)
(send t set-max-undo-history 100)

(define pb (new pasteboard%))
(send c set-editor pb)
(send c set accept-drop-files #t)

(define s (make-object editor-snip% t)) ; t is the old text editor
(send pb insert s)

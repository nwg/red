#lang info
(define collection "red-render")
(define deps '("base"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/red-render.scrbl" ())))
(define pkg-desc "Description Here")
(define version "0.0")
(define pkg-authors '(griswold))
(define copy-foreign-libs '("lib/libred-render-core-text.dylib"))

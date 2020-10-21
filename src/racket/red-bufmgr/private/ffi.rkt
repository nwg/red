#lang racket

(require ffi/unsafe)
(require ffi/unsafe/define)

(provide shm_open shm_unlink mmap munmap ftruncate close)
 

(define (check f)
 (λ (v who)
     (unless (f v)
       (error who "failed: ~a" v))
     v))

(define check-positive (check natural?))
(define check-zero (check zero?))

(define _off (make-ctype _int64 #f #f))
(define _void-pointer (_cpointer/null 'void))

(define-ffi-definer
  define-red-bufmgr
  (ffi-lib #f))
   
(define-red-bufmgr
  shmget
  (_fun _int32 _size _int -> (id : _int)
        -> (check-positive id 'shmget)))

(define-red-bufmgr
  shmat
  (_fun _int _uintptr _int -> (addr : _intptr)
        -> (check-positive addr 'shmat)))

(define-red-bufmgr
  shmdt
  (_fun _uintptr -> (r : _int)
        -> (check-zero r 'shmdt)))

;; int
;; shm_open(const char *name, int oflag, mode_t mode);
(define-red-bufmgr
  shm_open
  (_fun _string _int _int -> (r : _int)
        -> (check-positive r 'shm_open)))

;; int
;; shm_unlink(const char *name);
(define-red-bufmgr
  shm_unlink
  (_fun _string -> (r : _int)
        -> (check-zero r 'shm_unlink)))

;; void *
;; mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
(define-red-bufmgr
  mmap
  (_fun _pointer _size _int _int _int _off -> (r : _pointer)
        -> (begin
             (check-positive (cast r _pointer _sintptr) 'mmap)
             r)))

(define-red-bufmgr
  munmap
  (_fun _pointer _size -> (r : _int)
        -> (check-zero r 'munmap)))

(define-red-bufmgr
  ftruncate
  (_fun _int _off -> (r : _int)
        -> (check-zero r 'ftruncate)))


(define-red-bufmgr
  close
  (_fun _int -> (r : _int)
        -> (check-zero r 'close)))



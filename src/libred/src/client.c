#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>
#include <pthread/pthread.h>
#include <stdint.h>
#include <stdarg.h>
#include <stdio.h>

#include "client.h"
#include "work_queue.h"

typedef ptr (^argsBlock)(void);

static getproc_t get;
static putproc_t put;

__attribute__((noreturn)) void red_client_run_from_racket(getproc_t getproc, putproc_t putproc) {
  work_queue_init();

  get = getproc;
  put = putproc;
  
  put(Sstring_to_symbol("ready"));

  Sdeactivate_thread();
  work_queue_start();
}

static ptr racket_reverse_list(ptr args) {
  if (Snullp(args)) return Snil;
  
  ptr reversed = Snil;
  while (!Snullp(args)) {
    reversed = Scons(Scar(args), reversed);
    args = Scdr(args);
  }

  return reversed;
}

static ptr racket_list(ptr arg1, ...) {
  va_list argp;

  if (Snullp(arg1)) {
    return Snil;
  }
  
  va_start(argp, arg1);
  ptr args = Scons(arg1, Snil);

  ptr next = va_arg(argp, void*);
  while (!Snullp(next)) {
    args = Scons(next, args);
    next = va_arg(argp, void*);
  }

  va_end(argp);

  return racket_reverse_list(args);
}

static ptr run_standard_command(const char *cmd, argsBlock argsBlk) {
  pthread_mutex_t wait = PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t *waitPtr = &wait;
  pthread_mutex_lock(waitPtr);

  __block ptr result;
  
  work_queue_submit(^{
      Sactivate_thread();

      ptr arglist = Snil;
      if (argsBlk != NULL) {
	arglist = argsBlk();
      }

      arglist = Scons(Sstring_to_symbol(cmd), arglist);

      put(arglist);
      result = get();
      
      pthread_mutex_unlock(waitPtr);
      
      Sdeactivate_thread();
    });
  pthread_mutex_lock(waitPtr);
  pthread_mutex_unlock(waitPtr);

  return result;
}

static iptr run_iptr_command(const char *cmd, argsBlock argsBlk) {
  ptr result = run_standard_command(cmd, argsBlk);
  iptr status = -1;
  if (Sfixnump(result)) {
    status = Sinteger_value(result);
  }
  
  return status;
}

int red_client_test_call() {
  return (int)run_iptr_command("test-dispatch", NULL);
}

int red_client_register_memory(void *addr, size_t size, remote_memory_id_t *outid) {
  argsBlock blk = ^{
    return racket_list(Sunsigned64((uint64_t)addr), Sunsigned64(size), Snil);
  };

  iptr id_or_status = run_iptr_command("register-memory", blk);

  if (id_or_status < 0) {
    return -1;
  }

  if (outid) *outid = id_or_status;
  return 0;
}

int red_client_open_portal(remote_memory_id_t memory_id, int width, int height, remote_portal_id_t *outid) {
  argsBlock blk = ^{
    return racket_list(Sunsigned64(memory_id), Sunsigned64(width), Sunsigned64(height), Snil);
  };

  iptr id_or_status = run_iptr_command("open-portal", blk);

  if (id_or_status < 0) {
    return -1;
  }

  if (outid) *outid = id_or_status;
  return 0;
}

int red_client_create_buffer(remote_buffer_id_t *outid) {
  iptr id_or_status = run_iptr_command("create-buffer", NULL);

  if (id_or_status < 0) {
    return -1;
  }

  if (outid) *outid = id_or_status;
  return 0;
}

int red_client_buffer_open_file(remote_buffer_id_t buffer_id, const char *filename) {
  argsBlock blk = ^{
    return racket_list(Sunsigned64(buffer_id), Sstring(filename), Snil);
  };

  iptr id_or_status = run_iptr_command("buffer-open-file", blk);

  if (id_or_status < 0) {
    return -1;
  }

  return 0;
}

int red_client_draw_buffer_in_portal(remote_buffer_id_t buffer_id, remote_portal_id_t portal_id) {
  argsBlock blk = ^{
    return racket_list(Sunsigned64(buffer_id), Sunsigned64(portal_id), Snil);
  };

  iptr status = run_iptr_command("draw-buffer-in-portal", blk);

  if (status != 0) {
    return -1;
  }

  return 0;
}

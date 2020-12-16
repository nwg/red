#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>
#include <pthread/pthread.h>
#include <stdint.h>
#include <stdarg.h>
#include <stdio.h>

#include "client.h"
#include "work_queue.h"
#include "common.h"

typedef ptr (^argsBlock)(void);

typedef void (^resultBlock)(ptr result);

static getproc_t get;
static putproc_t put;

__attribute__((noreturn)) void red_client_run_from_racket(getproc_t getproc, putproc_t putproc) {
  work_queue_init();

  get = getproc;
  put = putproc;
  
  Sdeactivate_thread();

  work_queue_submit(^{
      put(Sstring_to_symbol("ready"));
    });
  
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

static void run_standard_command(const char *cmd, argsBlock argsBlk, resultBlock resultBlk) {
  pthread_mutex_t wait = PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t *waitPtr = &wait;
  pthread_mutex_lock(waitPtr);

  work_queue_submit(^{
      Sactivate_thread();

      ptr arglist = Snil;
      if (argsBlk != NULL) {
	arglist = argsBlk();
      }

      arglist = Scons(Sstring_to_symbol(cmd), arglist);

      put(arglist);
      ptr result = get();

      resultBlk(result);
      
      pthread_mutex_unlock(waitPtr);
      
      Sdeactivate_thread();
    });
  pthread_mutex_lock(waitPtr);
  pthread_mutex_unlock(waitPtr);
}

static iptr run_iptr_command(const char *cmd, argsBlock argsBlk) {
  __block iptr status = -1;
  resultBlock resultBlk = ^(ptr result) {
    status = Sinteger_value(result);
  };
  
  run_standard_command(cmd, argsBlk, resultBlk);
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

int red_client_set_current_bounds(remote_buffer_id_t buffer_id, red_bounds_t bounds) {
  argsBlock blk = ^{
    return racket_list(Sunsigned64(buffer_id), Sunsigned64(bounds.x),
		       Sunsigned64(bounds.y), Sunsigned64(bounds.w),
		       Sunsigned64(bounds.h), Snil);
  };

  iptr status = run_iptr_command("set-current-bounds", blk);
  if (status != 0) {
    return -1;
  }

  return 0;
}

int red_client_get_render_info(remote_portal_id_t portal_id, render_info_item_t items[RED_RENDER_ROWS][RED_RENDER_COLS]) {

  argsBlock argsBlk = ^{
    return racket_list(Sunsigned64(portal_id), Snil);
  };

  resultBlock resultBlk = ^(ptr result) {
    for (int i = 0; i < RED_RENDER_ROWS; i++) {
      ptr col = Svector_ref(result, i);
      for (int j = 0; j < RED_RENDER_COLS; j++) {
	ptr v = Svector_ref(col, j);
	iptr data = Sinteger_value(Svector_ref(v, 0));
	iptr i = Sinteger_value(Svector_ref(v, 1));
	iptr j = Sinteger_value(Svector_ref(v, 2));
	iptr x = Sinteger_value(Svector_ref(v, 3));
	iptr y = Sinteger_value(Svector_ref(v, 4));
	iptr w = Sinteger_value(Svector_ref(v, 5));
	iptr h = Sinteger_value(Svector_ref(v, 6));
	render_info_item_t *item = &items[i][j];
	item->data = (void*)data;
	item->i = i;
	item->j = j;
	item->x = x;
	item->y = y;
	item->w = w;
	item->h = h;
      }
    }
  };

  run_standard_command("get-render-info", argsBlk, resultBlk);

  return 0;
}

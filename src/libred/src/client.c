#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>
#include <pthread/pthread.h>
#include <stdint.h>

#include "client.h"
#include "work_queue.h"

typedef ptr (^argsBlock)(void);

__attribute__((noreturn)) void red_client_run_from_racket(ptr stash_path) {
  work_queue_init();

  racket_namespace_require(Sstring_to_symbol("racket/place"));
  racket_namespace_require(stash_path);
  
  ptr param = Scar(racket_eval(Sstring_to_symbol("client-channel")));
  ptr ch = Scar(racket_apply(param, Snil));
  ptr args = Scons(ch,
                   Scons(Sstring_to_symbol("ready"),
                         Snil));
  ptr put = Scar(racket_eval(Sstring_to_symbol("place-channel-put")));
  racket_apply(put, args);

  Sdeactivate_thread();
  work_queue_start();
}

static ptr args_to_list(ptr args[], int nargs) {
  ptr arglist = Snil;
  for (int i = nargs - 1; i >= 0; i--) {
    arglist = Scons(args[i], arglist);
  }

  return arglist;
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

      ptr param = Scar(racket_eval(Sstring_to_symbol("client-channel")));
      ptr ch = Scar(racket_apply(param, Snil));
                    
      arglist = Scons(Sstring_to_symbol(cmd), arglist);
      arglist = Scons(ch, Scons(arglist, Snil));

      ptr put = Scar(racket_eval(Sstring_to_symbol("place-channel-put")));
      racket_apply(put, arglist);

      ptr get = Scar(racket_eval(Sstring_to_symbol("place-channel-get")));
      result = racket_apply(get, Scons(ch, Snil));
      pthread_mutex_unlock(waitPtr);

      Sdeactivate_thread();
    });
  pthread_mutex_lock(waitPtr);
  pthread_mutex_unlock(waitPtr);

  return result;
}

static iptr run_iptr_command(const char *cmd, argsBlock argsBlk) {
  ptr result = run_standard_command(cmd, argsBlk);
  result = Scar(result);
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
    ptr args[] = { Sunsigned64((uint64_t)addr), Sunsigned64(size) };
    int argc = sizeof(args) / sizeof(args[0]);
    return args_to_list(args, argc);
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
    ptr args[] = { Sunsigned64(memory_id), Sunsigned64(width), Sunsigned64(height) };
    int argc = sizeof(args) / sizeof(args[0]);
    return args_to_list(args, argc);
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
    ptr args[] = { Sunsigned64(buffer_id), Sstring(filename) };
    int argc = sizeof(args) / sizeof(args[0]);
    return args_to_list(args, argc);
  };

  iptr id_or_status = run_iptr_command("buffer-open-file", blk);

  if (id_or_status < 0) {
    return -1;
  }

  return 0;
}

int red_client_draw_buffer_in_portal(remote_buffer_id_t buffer_id, remote_portal_id_t portal_id) {
  argsBlock blk = ^{
    ptr args[] = { Sunsigned64(buffer_id), Sunsigned64(portal_id) };
    int argc = sizeof(args) / sizeof(args[0]);
    return args_to_list(args, argc);
  };

  iptr status = run_iptr_command("draw-buffer-in-portal", blk);

  if (status != 0) {
    return -1;
  }

  return 0;
}

#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>
#include <pthread/pthread.h>
#include <stdint.h>

#include "client.h"
#include "work_queue.h"

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

static ptr run_standard_command(const char *cmd, ptr args[], int nargs) {
  pthread_mutex_t wait = PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t *waitPtr = &wait;
  pthread_mutex_lock(waitPtr);

  __block ptr result;
  
  work_queue_submit(^{
      Sactivate_thread();
      ptr arglist = Snil;
      for (int i = nargs - 1; i >= 0; i--) {
        arglist = Scons(args[i], arglist);
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

static iptr run_iptr_command(const char *cmd, ptr args[], int nargs) {
  ptr result = run_standard_command(cmd, args, nargs);
  result = Scar(result);
  iptr status = -1;
  if (Sfixnump(result)) {
    status = Sinteger_value(result);
  }
  
  return status;
}

int red_client_test_call() {
  return (int)run_iptr_command("test-dispatch", NULL, 0);
}

int red_client_register_memory(void *addr, size_t size, remote_memory_id_t *outid) {
  ptr args[] = { Sunsigned64((uint64_t)addr), Sunsigned64(size) };
  int argc = sizeof(args) / sizeof(args[0]);

  iptr id_or_status = run_iptr_command("register-memory", args, argc);

  if (id_or_status < 0) {
    return -1;
  }

  if (outid) *outid = id_or_status;
  return 0;
}

#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>
#include <pthread/pthread.h>

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

static int run_status_command(const char *cmd, ptr args[], int nargs) {
  ptr result = run_standard_command(cmd, args, nargs);
  result = Scar(result);
  int status = -1;
  if (Sfixnump(result)) {
    status = Sinteger_value(result);
  }
  
  return status;
}

int red_client_test_call() {
  return run_status_command("test-dispatch", NULL, 0);
}

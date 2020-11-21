#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>
#include <pthread/pthread.h>

#include "client.h"
#include "work_queue.h"

static ptr client_place_channel = NULL;
static ptr place_channel_put = NULL;
static ptr place_channel_get = NULL;

__attribute__((noreturn)) int red_client_run_from_racket(ptr ch, ptr put, ptr get) {
  client_place_channel = ch;
  place_channel_put = put;
  place_channel_get = get;
  work_queue_init();

  /* racket_namespace_require(Sstring_to_symbol("racket/place")); */
  ptr args = Scons(client_place_channel,
		   Scons(Sstring_to_symbol("ready"),
			 Snil));
  racket_apply(place_channel_put, args);
  Sdeactivate_thread();
  
  work_queue_start();
}

static int run_standard_command(const char *cmd, ptr args[], int nargs) {
  pthread_mutex_t wait = PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t *waitPtr = &wait;
  pthread_mutex_lock(waitPtr);

  __block int r;
  
  work_queue_submit(^{
      Sactivate_thread();
      ptr arglist = Snil;
      for (int i = nargs - 1; i >= 0; i--) {
	arglist = Scons(args[i], arglist);
      }

      arglist = Scons(Sstring_to_symbol(cmd), arglist);
      arglist = Scons(client_place_channel, Scons(arglist, Snil));

      racket_apply(place_channel_put, arglist);

      ptr result = racket_apply(place_channel_get, Scons(client_place_channel, Snil));
      result = Scar(result);
      if (!Sfixnump(result)) {
	r = -1;
      } else {
	r = Sinteger_value(result);
      }

      pthread_mutex_unlock(waitPtr);
    });
  pthread_mutex_lock(waitPtr);
  pthread_mutex_unlock(waitPtr);

  return r;
}

int red_client_test_call() {
  return run_standard_command("test-dispatch", NULL, 0);
}

#include <string.h>
#include <stddef.h>
#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>

#include "main.h"
#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>

#include "client.h"

typedef struct red_memory_s {
  void *addr;
  size_t size;
  remote_memory_id_t remote_id;
} red_memory_t;

typedef struct red_buffer_s {
  remote_buffer_id_t remote_id;
} red_buffer_t;

typedef struct red_portal_s {
  remote_portal_id_t remote_id;
  red_memory_t *memory;
} red_portal_t;

static int interpreter_stdin_pipe[2];
static int interpreter_stdout_pipe[2];

int libred_init(const char *execname, const char *petite, const char *scheme, const char *racket) {
    racket_boot_arguments_t ba;
    memset(&ba, 0, sizeof(ba));
    ba.boot1_path = petite;
    ba.boot2_path = scheme;
    ba.boot3_path = racket;

    ba.exec_file = execname;
    ba.collects_dir = "/Users/griswold/.red/collects";
    ba.config_dir = "/Users/griswold/.red/Racket/etc";

    char *argv[] = {
        "-n",
        "-A",
        "/Users/griswold/.red/Racket/addon",
        "-X",
        "/Users/griswold/.red/Racket/collects",
    };
    ba.argc = sizeof(argv) / sizeof(argv[0]);
    ba.argv = argv;

    racket_boot(&ba);

    racket_namespace_require(Sstring_to_symbol("red-dispatch"));

    pipe(interpreter_stdin_pipe);
    pipe(interpreter_stdout_pipe);
    ptr proc = Scar(racket_eval(Sstring_to_symbol("dispatch-init")));
    ptr args = Scons(Sunsigned((uint64_t)red_client_run_from_racket),
                     Scons(Sinteger(interpreter_stdin_pipe[0]),
                           Scons(Sinteger(interpreter_stdout_pipe[1]),
                                 Snil)));
    ptr result = racket_apply(proc, args);
    assert(Sinteger_value(Scar(result)) == 0);

    return 0;
}

LIBRED_EXPORT __attribute__((noreturn)) void libred_run(void) {
  ptr proc = Scar(racket_eval(Sstring_to_symbol("dispatch-run")));
  while (1) {
    racket_apply(proc, Snil);
  }
}

LIBRED_EXPORT int libred_test(void) {
  return red_client_test_call();
}

LIBRED_EXPORT int libred_register_memory(void *addr, size_t size, red_memory_t **outmemory) {
  remote_memory_id_t id;
  int status = red_client_register_memory(addr, size, &id);
  if (status != 0) {
    return -1;
  }

  if (outmemory) {
    red_memory_t *memory = malloc(sizeof(red_memory_t));
    memory->addr = addr;
    memory->size = size;
    memory->remote_id = id;
    *outmemory = memory;
  }

  return 0;
}

LIBRED_EXPORT int libred_open_portal(red_memory_t *memory, int width, int height, red_portal_t **outportal) {
  remote_portal_id_t id;
  int status = red_client_open_portal(memory->remote_id, width, height, &id);
  if (status != 0) {
    return -1;
  }

  if (outportal) {
    red_portal_t *portal = malloc(sizeof(red_portal_t));
    portal->remote_id = id;
    portal->memory = memory;
    *outportal = portal;
  }

  return 0;
}

LIBRED_EXPORT int libred_create_buffer(red_buffer_t **outbuffer) {
  remote_buffer_id_t id;
  int status = red_client_create_buffer(&id);
  if (status != 0) {
    return -1;
  }

  if (outbuffer) {
    red_buffer_t *buffer = malloc(sizeof(red_buffer_t));
    buffer->remote_id = id;
    *outbuffer = buffer;
  }

  return 0;
}

LIBRED_EXPORT int libred_buffer_open_file(red_buffer_t *buffer, const char *filename) {
  int status = red_client_buffer_open_file(buffer->remote_id, filename);
  if (status != 0) {
    return -1;
  }

  return 0;
}

LIBRED_EXPORT int libred_draw_buffer_in_portal(red_buffer_t *buffer, red_portal_t *portal) {
  int status = red_client_draw_buffer_in_portal(buffer->remote_id, portal->remote_id);
  if (status != 0) {
    return -1;
  }

  return 0;
}

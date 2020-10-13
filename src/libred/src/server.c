#include <string.h>
#include <stddef.h>
#include <stdio.h>
#include <zmq.h>
#include <assert.h>

#include "server.h"
#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>

static void *ctx = NULL;

void server_set_ctx(void *new_ctx) {
  ctx = new_ctx;
}

void *mm_server_get_ctx() {
    printf("Getting ctx\n");
    assert(ctx != NULL);
    return ctx;
}

int init_server(const char *execname, const char *petite, const char *scheme, const char *racket) {
    racket_boot_arguments_t ba;
    memset(&ba, 0, sizeof(ba));
    ba.boot1_path = petite;
    ba.boot2_path = scheme;
    ba.boot3_path = racket;

    ba.exec_file = execname;
    ba.collects_dir = "/Users/griswold/.red/collects";
    ba.config_dir = "/Users/griswold/.red/etc";

    ba.argc = 9;
    char *argv[] = {
        "-n",
//"--no-user-path",
        "-G",
        "/Users/griswold/.red/Racket/etc",
        "-A",
        "/Users/griswold/.red/Racket/addon",
        "-X",
        "/Applications/Racket v7.8/collects",
        "-W",
        "debug@ffi-lib",
    };
    ba.argv = argv;

    racket_boot(&ba);

    racket_namespace_require(Sstring_to_symbol("red-dispatch"));

    ptr proc;
    proc = Scar(racket_eval(Sstring_to_symbol("server-init")));
    ptr values = racket_apply(proc, Snil);
    ctx = Scar(values);
    assert(ctx != NULL);

    return 0;
}

int run_server() {
  ptr proc = Scar(racket_eval(Sstring_to_symbol("run-server")));
  racket_apply(proc, Snil);

  return 0;
}

buf_t *create_buffer() {
    return NULL;
}

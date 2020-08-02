#include <string.h>
#include <stddef.h>
#include <stdio.h>
#include <zmq.h>
#include <assert.h>

#include "server.h"
#include "chezscheme.h"
#include "racketcs.h"

static void *ctx = NULL;

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
        "/Applications/Racket v7.7/collects",
        "-W",
        "debug@ffi-lib",
    };
    ba.argv = argv;

    racket_boot(&ba);

    racket_namespace_require(Sstring_to_symbol("red-server"));

    ptr proc;
    proc = Scar(racket_eval(Sstring_to_symbol("server-init")));
    racket_apply(proc, Snil);

    assert(ctx != NULL);

    return 0;
}

int run_server() {
  ptr proc = Scar(racket_eval(Sstring_to_symbol("run-server")));
  racket_apply(proc, Snil);

  return 0;
}

void init_client_from_server(void *zmq_ctx) {
  printf("Client initialized\n");
  ctx = zmq_ctx;

}

void try_client() {
  assert(ctx != NULL);
  void *requester = zmq_socket(ctx, ZMQ_REQ);
  zmq_connect (requester, "inproc://dispatch");
  int request_nbr;
  for (request_nbr = 0; request_nbr != 10; request_nbr++) {
    char buffer [10];
    printf ("Sending Hello %d…\n", request_nbr);
    zmq_send (requester, "Hello", 5, 0);
    zmq_recv (requester, buffer, 10, 0);
    buffer[9] = '\0';
    printf ("Received World %d (%s)\n", request_nbr, buffer);
  }
}

  

buf_t *create_buffer() {
    return NULL;
}

#include <string.h>
#include <stddef.h>
#include <stdio.h>
#include <assert.h>
#include <unistd.h>

#include "main.h"
#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>

#include "client.h"

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
        "/Users/griswold/.red/Racket/collects",
        "-W",
        "debug@ffi-lib",
    };
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

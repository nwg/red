#include <string.h>
#include <stddef.h>

#include "server.h"
#include "chezscheme.h"
#include "racketcs.h"
#include "data.c"

struct buf_s {
};

int init_server(const char *execname, const char *petite, const char *scheme, const char *racket) {
    racket_boot_arguments_t ba;
    memset(&ba, 0, sizeof(ba));
    ba.boot1_path = petite;
    ba.boot2_path = scheme;
    ba.boot3_path = racket;

    ba.exec_file = execname;
    ba.collects_dir = "/Users/griswold/.red/collects";

    /*
    const char * home = getenv("HOME");
    char dotdir[PATH_MAX];
    strncpy(dotdir, home, PATH_MAX);
    strcat(dotdir, "/.red/etc");

    printf("outside dotdir=%s\n", dotdir);
    int r = mkpath(dotdir, S_IRWXU | S_IRWXG);
    if (r != 0) {
        printf("r was %d\n", r);
    }
    char realdotdir[PATH_MAX];
    const char *result = realpath(dotdir, realdotdir);
    printf("%s\n", realdotdir);
    assert(result != NULL);
    */

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

    declare_modules();

    /*
    racket_namespace_require(Sstring_to_symbol("red-server"));
    racket_eval(Scons(Sstring_to_symbol("red-server-run"), Snil));
    */

    ptr mod = Scons(Sstring_to_symbol("quote"),
                    Scons(Sstring_to_symbol("modules"),
                          Snil));
    racket_dynamic_require(mod, Sfalse);

    return 0;
}

buf_t *create_buffer() {
    return NULL;
}

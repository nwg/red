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

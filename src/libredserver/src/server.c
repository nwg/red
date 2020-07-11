#include <string.h>
#include <stddef.h>

#include "server.h"
#include "chezscheme.h"
#include "racketcs.h"
#include "data.c"

struct buf_s {
};

int init_server(const char *execname) {
    racket_boot_arguments_t ba;
    memset(&ba, 0, sizeof(ba));
    ba.boot1_path = "./petite.boot";
    ba.boot2_path = "./scheme.boot";
    ba.boot3_path = "./racket.boot";

    ba.exec_file = execname;

    racket_boot(&ba);

    declare_modules();

    ptr mod = Scons(Sstring_to_symbol("quote"),
                    Scons(Sstring_to_symbol("run"),
                          Snil));
    racket_dynamic_require(mod, Sfalse);

    return 0;
}

buf_t *create_buffer() {
    return NULL;
}

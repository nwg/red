#ifndef __SERVER_H__
#define __SERVER_H__

#include "libred.h"

typedef struct buf_s buf_t;

LIBRED_EXPORT buf_t *create_buffer();
LIBRED_EXPORT int init_server(const char *execname, const char *petite, const char *scheme, const char *racket);
LIBRED_EXPORT int run_server();

#endif

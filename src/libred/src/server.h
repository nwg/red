#ifndef __SERVER_H__
#define __SERVER_H__

#define RED_SERVER_EXPORT __attribute__((visibility("default")))

typedef struct buf_s buf_t;

RED_SERVER_EXPORT buf_t *create_buffer();
RED_SERVER_EXPORT int init_server(const char *execname, const char *petite, const char *scheme, const char *racket);
RED_SERVER_EXPORT void try_client();
RED_SERVER_EXPORT int run_server();

#endif

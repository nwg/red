#ifndef __LIBRED_H__
#define __LIBRED_H__

#include <stddef.h>

#define LIBRED_EXPORT __attribute__((visibility("default")))

struct red_buffer_s;
struct red_shm_s;
typedef struct red_buffer_s red_buffer_t;
typedef struct red_shm_s red_shm_t;

LIBRED_EXPORT int libred_init(const char *client_socket_fn);
LIBRED_EXPORT int libred_load_file(const char *fn, red_buffer_t **outbuf);
LIBRED_EXPORT int libred_create_and_attach_shared_memory(size_t size, red_shm_t **outshm);

LIBRED_EXPORT int libred_detach_shared_memory(red_shm_t *shm);

#endif

#ifndef __LIBRED_H__
#define __LIBRED_H__

#include <stddef.h>

#define LIBRED_EXPORT __attribute__((visibility("default")))

struct red_buffer_s;
struct red_shm_s;
typedef struct red_buffer_s red_buffer_t;
typedef struct red_shm_s red_shm_t;

LIBRED_EXPORT int libred_init(const char *client_socket_fn);
LIBRED_EXPORT red_buffer_t *libred_load_file(const char *fn);
LIBRED_EXPORT red_shm_t *libred_create_and_attach_shared_memory(size_t size);
LIBRED_EXPORT int libred_detach_shared_memory(red_shm_t *shm);

#endif

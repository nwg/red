#ifndef __LIBRED_H__
#define __LIBRED_H__

#include <stddef.h>

#define LIBRED_EXPORT __attribute__((visibility("default")))

struct red_buffer_s;
struct red_shm_s;
struct red_portal_s;
typedef struct red_buffer_s red_buffer_t;
typedef struct red_shm_s red_shm_t;
typedef struct red_portal_s red_portal_t;

LIBRED_EXPORT int libred_init();
LIBRED_EXPORT int libred_load_file(const char *fn, red_buffer_t **outbuf);
LIBRED_EXPORT int libred_create_and_attach_shared_memory(size_t size, red_shm_t **outshm);

LIBRED_EXPORT int libred_detach_shared_memory(red_shm_t *shm);

LIBRED_EXPORT int libred_open_portal(red_shm_t *shm, int width, int height, red_portal_t **outportal);

LIBRED_EXPORT int libred_close_portal(red_portal_t *portal);

LIBRED_EXPORT int libred_draw_buffer_in_portal(red_buffer_t *buffer, red_portal_t *portal);

LIBRED_EXPORT void *libred_shm_get_addr(red_shm_t *shm);

#endif

#ifndef __LIBRED_CLIENT_H__
#define __LIBRED_CLIENT_H__

#include <sys/shm.h>

#include "libred.h"

typedef int64_t remote_buffer_id_t;
typedef int64_t remote_shm_id_t;
typedef int64_t remote_portal_id_t;

LIBRED_EXPORT int mm_client_init(const char *socketfn);

LIBRED_EXPORT int mm_client_backend_load_renderer(const char *renderer);
LIBRED_EXPORT remote_buffer_id_t mm_client_backend_load_file(const char *filename);

int mm_client_backend_attach_shared_memory(const char *path, size_t size, remote_shm_id_t *outid);

int mm_client_detach_shared_memory(remote_shm_id_t id);

int mm_client_open_portal(remote_shm_id_t shmid, int width, int height, remote_portal_id_t *outid);

int mm_client_close_portal(remote_portal_id_t pid);

int mm_client_draw_buffer_in_portal(remote_buffer_id_t bufid, remote_portal_id_t pid);

#endif

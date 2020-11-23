#ifndef __LIBRED_CLIENT_H__
#define __LIBRED_CLIENT_H__

#include <Racket/chezscheme.h>

typedef int64_t remote_buffer_id_t;
typedef int64_t remote_memory_id_t;
typedef int64_t remote_portal_id_t;

__attribute__((noreturn)) void red_client_run_from_racket(ptr stash_path);

int red_client_test_call();
int red_client_register_memory(void *addr, size_t size, remote_memory_id_t *outid);
int red_client_open_portal(remote_memory_id_t memory_id, int width, int height, remote_portal_id_t *outid);
int red_client_create_buffer(remote_buffer_id_t *outbuf);
int red_client_buffer_open_file(remote_buffer_id_t buffer_id, const char *filename);
int red_client_draw_buffer_in_portal(remote_buffer_id_t buffer_id, remote_portal_id_t portal_id);

#endif

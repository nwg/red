#ifndef __LIBRED_CLIENT_H__
#define __LIBRED_CLIENT_H__

#include <Racket/chezscheme.h>

typedef int64_t remote_buffer_id_t;
typedef int64_t remote_memory_id_t;
typedef int64_t remote_portal_id_t;

__attribute__((noreturn)) void red_client_run_from_racket(ptr stash_path);

int red_client_test_call();
int red_client_register_memory(void *addr, size_t size, remote_memory_id_t *outid);

#endif

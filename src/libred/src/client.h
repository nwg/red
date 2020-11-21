#ifndef __LIBRED_CLIENT_H__
#define __LIBRED_CLIENT_H__

#include <Racket/chezscheme.h>

typedef int64_t remote_buffer_id_t;
typedef int64_t remote_shm_id_t;
typedef int64_t remote_portal_id_t;

__attribute__((noreturn)) int red_client_run_from_racket(ptr ch, ptr put, ptr get);

int red_client_test_call();

#endif

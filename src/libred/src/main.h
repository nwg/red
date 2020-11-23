#ifndef __MAIN_H__
#define __MAIN_H__

#include <stddef.h>

#define LIBRED_EXPORT __attribute__((visibility("default")))

struct red_buffer_s;
struct red_memory_s;
struct red_portal_s;
typedef struct red_buffer_s red_buffer_t;
typedef struct red_memory_s red_memory_t;
typedef struct red_portal_s red_portal_t;

LIBRED_EXPORT int libred_init(const char *execname, const char *petite, const char *scheme, const char *racket);

LIBRED_EXPORT __attribute__((noreturn)) void libred_run(void);
LIBRED_EXPORT int libred_test(void);
LIBRED_EXPORT int libred_register_memory(void *addr, size_t size, red_memory_t **outmemory);

#endif

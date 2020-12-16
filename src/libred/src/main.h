#ifndef __MAIN_H__
#define __MAIN_H__

#include <stddef.h>
#include "types.h"
#include "common.h"

#define LIBRED_EXPORT __attribute__((visibility("default")))

struct red_buffer_s;
struct red_memory_s;
struct red_portal_s;
typedef struct red_buffer_s red_buffer_t;
typedef struct red_memory_s red_memory_t;
typedef struct red_portal_s red_portal_t;

typedef struct red_tile_s {
  void *data;
  int i;
  int j;
  int x;
  int y;
  int w;
  int h;
} red_tile_t;

typedef struct red_render_info_s {
  red_tile_t tiles[RED_RENDER_ROWS][RED_RENDER_COLS];
  int rows;
  int cols;
} red_render_info_t;

LIBRED_EXPORT int libred_init(const char *execname, const char *petite, const char *scheme, const char *racket);

LIBRED_EXPORT __attribute__((noreturn)) void libred_run(void);
LIBRED_EXPORT int libred_test(void);
LIBRED_EXPORT int libred_register_memory(void *addr, size_t size, red_memory_t **outmemory);
LIBRED_EXPORT int libred_open_portal(red_buffer_t *buffer, int width, int height, red_portal_t **outportal);
LIBRED_EXPORT int libred_create_buffer(red_buffer_t **outbuffer);
LIBRED_EXPORT int libred_buffer_open_file(red_buffer_t *buffer, const char *filename);
LIBRED_EXPORT int libred_draw_buffer_in_portal(red_buffer_t *buffer, red_portal_t *portal);
LIBRED_EXPORT int libred_set_current_bounds(red_buffer_t *buffer, red_bounds_t bounds);
LIBRED_EXPORT int libred_get_render_info(red_portal_t *portal, red_render_info_t *destinfo);

#endif

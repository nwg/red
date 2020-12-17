#ifndef __LIBRED_CLIENT_H__
#define __LIBRED_CLIENT_H__

#include <Racket/chezscheme.h>
#include "types.h"
#include "common.h"

typedef struct render_info_item_s {
  void *data;
  int i;
  int j;
  int x;
  int y;
  int w;
  int h;
} render_info_item_t;

typedef int64_t remote_buffer_id_t;
typedef int64_t remote_memory_id_t;
typedef int64_t remote_portal_id_t;

typedef void (*putproc_t)(ptr);
typedef ptr (*getproc_t)(void);

__attribute__((noreturn)) void red_client_run_from_racket(putproc_t rdyproc, getproc_t getproc, putproc_t putproc);

int red_client_test_call();
int red_client_register_memory(void *addr, size_t size, remote_memory_id_t *outid);
int red_client_open_portal(remote_memory_id_t memory_id, int width, int height, remote_portal_id_t *outid);
int red_client_create_buffer(remote_buffer_id_t *outbuf);
int red_client_buffer_open_file(remote_buffer_id_t buffer_id, const char *filename);
int red_client_draw_buffer_in_portal(remote_buffer_id_t buffer_id, remote_portal_id_t portal_id);
int red_client_set_current_bounds(remote_buffer_id_t buffer_id, red_bounds_t bounds);
int red_client_get_render_info(remote_portal_id_t portal_id, render_info_item_t items[RED_RENDER_ROWS][RED_RENDER_COLS]);

#endif

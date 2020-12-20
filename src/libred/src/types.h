#ifndef __RED_TYPES_H__
#define __RED_TYPES_H__

#include <stdint.h>

typedef struct {
  uint64_t x;
  uint64_t y;
  uint64_t w;
  uint64_t h;
} red_bounds_t;

typedef struct red_render_info_s {
  int64_t rows;
  int64_t cols;
  int64_t tile_width;
  int64_t tile_height;
  int64_t total_width;
  int64_t total_height;
} red_render_info_t;

#endif

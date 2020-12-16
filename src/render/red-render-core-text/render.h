//
//  render.h
//  red-render-core-text
//
//  Created by Nathaniel W Griswold on 7/14/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

#ifndef render_h
#define render_h

#include <stdio.h>
#include <stddef.h>

typedef float  float32_t;
typedef double float64_t;

typedef struct {
    float64_t ascent;
    float64_t descent;
    float64_t leading;
    float64_t width;
    CTLineRef line;
} red_render_line_info_t;

#define EXPORT __attribute__((visibility("default")))

EXPORT int red_render_init(void);
EXPORT void red_render_get_line_info(const char *lineText, int numBytes, red_render_line_info_t *outInfo);
EXPORT void red_render_free_line_info(red_render_line_info_t *lineInfo);
EXPORT CGContextRef red_render_create_context(int width, int height, void *data);
EXPORT void red_render_destroy_context(CGContextRef ctx);
EXPORT CGFloat red_render_get_line_height(void);
EXPORT void red_render_draw_line(CGContextRef ctx, red_render_line_info_t *lineInfo, double xStart, double yStart);
EXPORT void red_render_clear_rect(CGContextRef ctx, int x, int y, int width, int height);

#endif /* render_h */

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
} red_render_line_info_t;

#define EXPORT __attribute__((visibility("default")))

EXPORT int red_render_init(void);
EXPORT void red_render_get_line_info(const char *lineText, int numBytes, red_render_line_info_t *outInfo);
EXPORT void *red_render_create_context(int width, int height, void *data);

#endif /* render_h */

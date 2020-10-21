//
//  render.c
//  red-render-core-text
//
//  Created by Nathaniel W Griswold on 7/14/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

#include <CoreText/CoreText.h>
#include "render.h"

#if !defined(ARRAY_SIZE)
 #define ARRAY_SIZE(x) (sizeof((x)) / sizeof((x)[0]))
#endif

static CTFontRef font;
static CFDictionaryRef attributes;
static CGColorRef defaultColor;

EXPORT int red_render_init(void) {
    font = CTFontCreateWithName(CFSTR("Helvetica"), 14.f, NULL);
    
    CGFloat colors[] = { 0.0, 0.0, 1.0, 1.0 };
    defaultColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), colors);
    int ligatureValue = 1;
    const void *keys[] = { kCTFontAttributeName, kCTLigatureAttributeName, kCTForegroundColorAttributeName };
    const void *values[] = { font, CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &ligatureValue), defaultColor };
    size_t numValues = ARRAY_SIZE(values);
    attributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, numValues, NULL, NULL);
    
    return 0;
}

EXPORT void red_render_get_line_info(const char *lineText, int numBytes, red_render_line_info_t *outInfo) {
    assert(outInfo);
    
    printf("Getting line info for %s\n", lineText);
    CFStringRef str = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8*)lineText, numBytes, kCFStringEncodingUTF8, false, kCFAllocatorNull);
    CFAttributedStringRef attr = CFAttributedStringCreate(kCFAllocatorDefault, str, attributes);
    CTLineRef line = CTLineCreateWithAttributedString(attr);
    
    outInfo->width = CTLineGetTypographicBounds(line, &outInfo->ascent, &outInfo->descent, &outInfo->leading);
    outInfo->line = line;
    
    CFRelease(str);
    CFRelease(attr);
}

EXPORT void red_render_free_line_info(red_render_line_info_t *lineInfo) {
    CFRelease(lineInfo);
}

EXPORT CGContextRef red_render_create_context(int width, int height, void *data) {
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder32Little;
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width*4, space, bitmapInfo);
    CGColorSpaceRelease(space);
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    CGContextSetTextDrawingMode(ctx, kCGTextFill);
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0); // white background
    CGContextFillRect(ctx, CGRectMake(0.0, 0.0, width, height));
    
    return ctx;
}

EXPORT void red_render_draw_line(CGContextRef ctx, red_render_line_info_t *lineInfo, double xStart, double yStart) {
    CGFloat x = xStart;
    CGFloat y = yStart + lineInfo->descent;
    CGContextSetTextPosition(ctx, x, y);

    CTLineRef line = lineInfo->line;
    CTLineDraw(line, ctx);
}

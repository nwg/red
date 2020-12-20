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
    CGAffineTransform t = CGAffineTransformScale(CGAffineTransformIdentity, 2.0, -2.0);
    CFStringRef fontString = CFStringCreateWithCString(NULL, "SF Mono", kCFStringEncodingUnicode);
    font = CTFontCreateWithName(fontString, 12.f, &t);
    CFRelease(fontString);
    CGFloat colors[] = { 108.f/255, 121.f/255, 134.f/255, 1.0 };
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
    
    CFStringRef str = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8*)lineText, numBytes, kCFStringEncodingUTF8, false, kCFAllocatorNull);
    CFAttributedStringRef attr = CFAttributedStringCreate(kCFAllocatorDefault, str, attributes);
    CTLineRef line = CTLineCreateWithAttributedString(attr);

    outInfo->width = CTLineGetTypographicBounds(line, &outInfo->ascent, &outInfo->descent, &outInfo->leading);
    outInfo->line = line;

    CFRelease(str);
    CFRelease(attr);
}

EXPORT void red_render_free_line_info(red_render_line_info_t *lineInfo) {
    CFRelease(lineInfo->line);
}

EXPORT CGContextRef red_render_create_context(int width, int height, void *data) {
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder32Little;
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width*4, space, bitmapInfo);
    CGColorSpaceRelease(space);
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    CGContextSetTextDrawingMode(ctx, kCGTextFill);
    CGContextSetRGBFillColor(ctx, 37/255.f, 38/255.f, 45/255.f, 1.0);
    CGContextFillRect(ctx, CGRectMake(0.0, 0.0, width, height));
    CGContextScaleCTM(ctx, 1., -1.);
    CGContextTranslateCTM(ctx, 0., -(CGFloat)height);
    
    return ctx;
}

EXPORT void red_render_destroy_context(CGContextRef ctx) {
    CFRelease(ctx);
}

EXPORT void red_render_get_font_info(red_render_font_info_t *info) {
    info->ascent = CTFontGetAscent(font);
    info->descent = CTFontGetDescent(font);
    info->leading = CTFontGetLeading(font);
}

EXPORT void red_render_clear_rect(CGContextRef ctx, int x, int y, int width, int height) {
    CGContextSetRGBFillColor(ctx, 37/255.f, 38/255.f, 48/255.f, 1.0); // white background
    CGContextFillRect(ctx, CGRectMake(x, y, width, height));
}

EXPORT void red_render_draw_line(CGContextRef ctx, CTLineRef line, double xStart, double yStart) {
    CGContextSetTextPosition(ctx, xStart, yStart);
    CTLineDraw(line, ctx);
}

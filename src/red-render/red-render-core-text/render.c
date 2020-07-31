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

EXPORT int red_render_init(void) {
    font = CTFontCreateWithName(CFSTR("Helvetica"), 14.f, NULL);
    
    int ligatureValue = 1;
    const void *keys[] = { kCTFontAttributeName, kCTLigatureAttributeName };
    const void *values[] = { font, CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &ligatureValue) };
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
    
    CFRelease(str);
    CFRelease(attr);
    CFRelease(line);
}

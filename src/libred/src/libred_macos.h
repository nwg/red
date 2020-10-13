#ifndef __LIBRED_MACOS_H__
#define __LIBRED_MACOS_H__

#include <CoreFoundation/CoreFoundation.h>

int libred_macos_init();

CFRunLoopRef mm_get_runloop();

#endif

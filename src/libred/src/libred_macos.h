#ifndef __LIBRED_MACOS_H__
#define __LIBRED_MACOS_H__

#include <CoreFoundation/CoreFoundation.h>

CFRunLoopRef libred_macos_create_runloop();
__attribute__((noreturn)) void libred_macos_run_runloop();
void libred_macos_runloop_perform_block(CFRunLoopRef runLoop, void (^blk)(void));

#endif

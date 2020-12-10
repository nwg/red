#include <mach/mach_time.h>

#include "libred_macos.h"

CFRunLoopRef libred_macos_create_runloop() {
  CFMachPortRef port = CFMachPortCreate(NULL, NULL, NULL, NULL);
  assert(port);
  CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(NULL, port, 0);
  CFRunLoopRef runLoop = CFRunLoopGetCurrent();
  assert(runLoop);
  CFRunLoopAddSource(runLoop, source, kCFRunLoopDefaultMode);

  return runLoop;
}

__attribute__((noreturn)) void libred_macos_run_runloop() {
  while (true) {
    CFRunLoopRun();
  }

  __builtin_unreachable();
}

void libred_macos_runloop_perform_block(CFRunLoopRef runLoop, void (^blk)(void)) {
    CFRunLoopPerformBlock(
                        runLoop,
                        kCFRunLoopDefaultMode,
                        blk);

    CFRunLoopWakeUp(runLoop);
}

int libred_macos_uptime_ms() {
    const int64_t kOneMillion = 1000 * 1000;
    static mach_timebase_info_data_t s_timebase_info;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        (void) mach_timebase_info(&s_timebase_info);
    });

    // mach_absolute_time() returns billionth of seconds,
    // so divide by one million to get milliseconds
    return (int)((mach_absolute_time() * s_timebase_info.numer) / (kOneMillion * s_timebase_info.denom));
}

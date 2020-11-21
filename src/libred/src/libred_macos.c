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

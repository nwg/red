#include "work_queue.h"

#include "libred_macos.h"

static CFRunLoopRef runLoop = NULL;

int work_queue_init() {
  runLoop = libred_macos_create_runloop();
  printf("initialized runLoop %p\n", (void*)runLoop);
  return 0;
}

__attribute__((noreturn)) void work_queue_start() {
  libred_macos_run_runloop();
}

int work_queue_submit(workBlock blk) {
  libred_macos_runloop_perform_block(runLoop, blk);
  return 0;
}

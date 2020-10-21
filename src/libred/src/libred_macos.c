#include <pthread.h>

#include "libred_macos.h"

static pthread_t thread;

static CFRunLoopRef runLoop;

static pthread_mutex_t waitInit = PTHREAD_MUTEX_INITIALIZER;

static void *start_runloop(void *data) {
  (void)data;
  CFMachPortRef port = CFMachPortCreate(NULL, NULL, NULL, NULL);
  assert(port);
  CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(NULL, port, 0);
  /* CFRunLoopSourceContext ctx; */
  /* CFRunLoopSourceRef source = CFRunLoopSourceCreate(NULL, 0, &ctx); */
  /* assert(source); */
  runLoop = CFRunLoopGetCurrent();
  assert(runLoop);
  CFRunLoopAddSource(runLoop, source, kCFRunLoopDefaultMode);

  uint64_t tid;
  pthread_threadid_np(NULL, &tid);
  printf("Thread starting runloop on thread %llu\n", tid);
  pthread_mutex_unlock(&waitInit);

  while (true) {
    CFRunLoopRun();
    printf("Running runloop again\n");
  }
  printf("Shutting down runloop thread\n");
  pthread_exit(NULL);
}

int libred_macos_init() {
  pthread_mutex_lock(&waitInit);
  int status = pthread_create(&thread, NULL, start_runloop, NULL);
  if (status != 0) {
    return -1;
  }

  pthread_mutex_lock(&waitInit);

  printf("initialized macos\n");
  return 0;
}

CFRunLoopRef mm_get_runloop() {
  return runLoop;
}

void MMSyncRunLoop(CFRunLoopRef runLoop, CFStringRef mode) {
  assert(runLoop != CFRunLoopGetCurrent());
  pthread_mutex_t wait = PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t *waitPtr = &wait;
  pthread_mutex_lock(&wait);
  CFRunLoopPerformBlock(
			runLoop,
			mode,
			^{
			  pthread_mutex_unlock(waitPtr);
			});
  CFRunLoopWakeUp(runLoop);
  pthread_mutex_lock(&wait);			
}


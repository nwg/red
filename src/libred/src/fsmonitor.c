#include <CoreServices/CoreServices.h>
#include <libgen.h>
#include <sys/fcntl.h>

#include "fsmonitor.h"
#include "libred_macos.h"

#define LATENCY 0.5

static FSEventStreamRef stream = NULL;
static const char *currentPath = NULL;
static fs_monitor_callback_t currentCallback = NULL;

static void eventCallback(
    ConstFSEventStreamRef streamRef,
    void *clientCallBackInfo,
    size_t numEvents,
    void *eventPaths,
    const FSEventStreamEventFlags eventFlags[],
    const FSEventStreamEventId eventIds[])
{
    int i;
    char **paths = eventPaths;
 
    // printf("Callback called\n");
    for (i=0; i<numEvents; i++) {
        int count;
        /* flags are unsigned long, IDs are uint64_t */

	if (strcmp(currentPath, paths[i]) == 0) {
	  FSEventStreamEventFlags flags = eventFlags[i];
	  printf("Change %llu in %s, flags %lu\n", eventIds[i], paths[i], (unsigned long int)flags);
	  assert(flags & kFSEventStreamEventFlagItemIsFile);
	  if (currentCallback != NULL) {
	    currentCallback();
	  }
	}
   }
}

int fs_start_watching_file(const char *path, fs_monitor_callback_t callback) {
  assert(currentPath == NULL);
  
  int fd = open(path, O_RDONLY);
  char resolved[PATH_MAX];
  if (fcntl(fd, F_GETPATH, resolved) < 0) {
    close(fd);
    return -1;
  }
  close(fd);
  printf("Path is %s\n", resolved);
  
  currentPath = strdup(resolved);
  const char *dir = dirname((char*)resolved);
  printf("Watching dir %s\n", dir);
  CFStringRef mypath = CFStringCreateWithBytes(NULL, (const UInt8*)dir, strlen(dir), kCFStringEncodingUTF8, false);

  CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&mypath, 1, NULL);
  void *callbackInfo = NULL; // could put stream-specific data here.
  CFAbsoluteTime latency = LATENCY; /* Latency in seconds */

  /* Create the stream, passing in a callback */

  stream = FSEventStreamCreate(
			       NULL,
			       &eventCallback,
			       callbackInfo,
			       pathsToWatch,
			       kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
			       latency,
			       kFSEventStreamCreateFlagFileEvents /* Flags explained in reference */
			       );

  CFRelease(pathsToWatch);
  CFRelease(mypath);

  assert(stream);

  assert(mm_get_runloop());
  FSEventStreamScheduleWithRunLoop(stream, mm_get_runloop(), kCFRunLoopDefaultMode);

  currentCallback = callback;
  
  FSEventStreamStart(stream);

  return 0;
}

int fs_stop_watching_file() {
  assert(currentPath != NULL);
  /* CFRunLoopWakeUp(mm_get_runloop()); */
  FSEventStreamFlushSync(stream);
  MMSyncRunLoop(mm_get_runloop(), kCFRunLoopDefaultMode);
  FSEventStreamStop(stream);
  FSEventStreamUnscheduleFromRunLoop(stream, mm_get_runloop(), kCFRunLoopDefaultMode);
  FSEventStreamInvalidate(stream);
  FSEventStreamRelease(stream);
  stream = NULL;
  currentPath = NULL;
  currentCallback = NULL;

  return 0;
}

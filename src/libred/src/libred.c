#include <stdio.h>
#include <sys/mman.h>

#include "libred.h"
#include "client.h"
#include "libred_macos.h"
#include "fsmonitor.h"

int libred_init(const char *client_socket_fn) {
  printf("libred_init\n");
  int status = libred_macos_init();
  if (status != 0) {
    return status;
  }

  assert(mm_get_runloop());
  return mm_client_init(client_socket_fn);
}

void file_changed_callback(const char *path, void *data) {
  printf("File changed\n");
}

int libred_load_file(const char *fn) {
  printf("Watching file %s\n", fn);
  fs_start_watching_file(fn, file_changed_callback, NULL);
  return 0;
}

#include <stdio.h>
#include <sys/mman.h>
#include <stdbool.h>
#include <sys/stat.h>

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
  __block bool changed = false;
  fs_start_watching_file(fn, ^{
      printf("File changed block\n");
      changed = true;
    });

  int fd = open(fn, O_RDONLY);
  if (fd < 0) return -1;

  struct stat s;
  int status = fstat(fd, &s);
  if (status < 0) return -1;

  size_t len = s.st_size;

  const char *mapped = mmap(0, len, PROT_READ, MAP_PRIVATE, fd, 0);
  if (mapped == MAP_FAILED) return -1;

  
  while (!changed) {
    // read file
    sleep(5);
    break;
  }

  fs_stop_watching_file();
  close(fd);
  munmap((void*)mapped, len);

  if (changed) {
    printf("Error -- file %s changed on disk during read\n", fn);
    return -1;
  }
  
  return 0;
}


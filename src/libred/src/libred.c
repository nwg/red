#include <stdio.h>
#include <sys/mman.h>
#include <stdbool.h>
#include <sys/stat.h>

#include "libred.h"
#include "client.h"
#include "libred_macos.h"
#include "fsmonitor.h"

typedef struct red_shm_s {
  void *addr;
  size_t size;
  remote_shm_id_t remote_id;
} red_shm_t;

typedef struct red_buffer_s {
  remote_buffer_id_t remote_id;
} red_buffer_t;

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
  (void)path;
  (void)data;
  printf("File changed\n");
}

red_buffer_t *libred_load_file(const char *fn) {
  remote_buffer_id_t remote_id = mm_client_backend_load_file(fn);
  if (remote_id < 0) {
    return NULL;
  }

  red_buffer_t *outbuf = malloc(sizeof(red_buffer_t));
  outbuf->remote_id = remote_id;

  return outbuf;
}

static uint64_t count;
static inline uint64_t get_unique_shm() {
  return count++;
}

red_shm_t *libred_create_and_attach_shared_memory(size_t size) {
  remote_shm_id_t remote_id;
  char path[PATH_MAX];
  snprintf(path, PATH_MAX, "com.manicmind.Red-%d-shm-%llu", getpid(), get_unique_shm());

  int error = 0;
  
  int fd = shm_open(path, O_CREAT | O_EXCL | O_RDWR, S_IRUSR | S_IWUSR);
  if (fd == -1) {
    printf("shmget failed\n");
    error= -1;
    goto finish;
  }

  if (ftruncate(fd, size) == -1) {
    printf("truncate failed\n");
    error= -1;
    goto finish;
  }
  
  void *addr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (addr == (void*)-1) {
    printf("mmap failed\n");
    error= -1;
    goto finish;
  }

  printf("Calling server to attach %s with size %zu\n", path, size);
  int result = mm_client_backend_attach_shared_memory(path, size, &remote_id);
  if (result != 0) {
    error= -1;
    goto finish;
  }

 finish:
  if (fd >= 0) {
    result = close(fd);
    if (result != 0) abort();
  }
  result = shm_unlink(path);
  if (result != 0) abort();
  if (error != 0) return NULL;

  red_shm_t *outshm = malloc(sizeof(red_shm_t));
  outshm->remote_id = remote_id;
  outshm->size = size;
  outshm->addr = addr;

  return outshm;
}

int libred_detach_shared_memory(red_shm_t *shm) {
  mm_client_detach_shared_memory(shm->remote_id);
  int status = munmap(shm->addr, shm->size);
  if (status != 0) abort();

  free(shm);

  return 0;
}

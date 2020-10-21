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

typedef struct red_portal_s {
  remote_portal_id_t remote_id;
  red_shm_t *shm;
} red_portal_t;

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

int libred_load_file(const char *fn, red_buffer_t **outbuf) {
  remote_buffer_id_t remote_id = mm_client_backend_load_file(fn);
  if (remote_id < 0) {
    return -1;
  }

  if (outbuf) {
    red_buffer_t *buf = malloc(sizeof(red_buffer_t));
    buf->remote_id = remote_id;
    *outbuf = buf;
  }

  return 0;
}

static uint64_t count;
static inline uint64_t get_unique_shm() {
  return count++;
}

int libred_create_and_attach_shared_memory(size_t size, red_shm_t **outshm) {
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
  if (error != 0) return error;

  if (outshm) {
    red_shm_t *shm = malloc(sizeof(red_shm_t));
    shm->remote_id = remote_id;
    shm->size = size;
    shm->addr = addr;
    *outshm = shm;
  }

  return 0;
}

int libred_detach_shared_memory(red_shm_t *shm) {
  int status = mm_client_detach_shared_memory(shm->remote_id);
  if (status != 0) return -1;
  status = munmap(shm->addr, shm->size);
  if (status != 0) return -1;

  free(shm);

  return 0;
}

LIBRED_EXPORT int libred_draw_buffer_in_portal(red_buffer_t *buffer, red_portal_t *portal) {
  return mm_client_draw_buffer_in_portal(buffer->remote_id, portal->remote_id);
}

LIBRED_EXPORT int libred_open_portal(red_shm_t *shm, int width, int height, red_portal_t **outportal) {
  remote_portal_id_t pid;
  int status = mm_client_open_portal(shm->remote_id, width, height, &pid);
  if (status != 0) return -1;

  if (outportal) {
    red_portal_t *portal = malloc(sizeof(portal));
    portal->remote_id = pid;
    portal->shm = shm;
    *outportal = portal;
  }

  return 0;
}

LIBRED_EXPORT void *libred_shm_get_addr(red_shm_t *shm) {
  return shm->addr;
}

LIBRED_EXPORT int libred_close_portal(red_portal_t *portal) {
  int status = mm_client_close_portal(portal->remote_id);
  if (status != 0) return -1;

  free(portal);

  return 0;
}


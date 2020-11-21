#include <assert.h>
#include <zmq.h>
#include <msgpack.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include <Racket/chezscheme.h>
#include <Racket/racketcs.h>
#include <pthread/pthread.h>

#include "client.h"
#include "work_queue.h"

static void *requester;

static msgpack_sbuffer sbuf;
static msgpack_packer pk;
static msgpack_zone mempool;

#define MAX_RECV_SIZE 4096
static char recvbuf[MAX_RECV_SIZE];

static ptr client_place_channel = NULL;
static ptr place_channel_put = NULL;
static ptr place_channel_get = NULL;

#define REMOTE_STATUS_MIN INT_MIN
#define REMOTE_STATUS_MAX INT_MAX

__attribute__((noreturn)) int red_client_run_from_racket(ptr ch, ptr put, ptr get) {
  client_place_channel = ch;
  place_channel_put = put;
  place_channel_get = get;
  work_queue_init();

  /* racket_namespace_require(Sstring_to_symbol("racket/place")); */
  ptr args = Scons(client_place_channel,
		   Scons(Sstring_to_symbol("ready"),
			 Snil));
  racket_apply(place_channel_put, args);
  Sdeactivate_thread();
  
  work_queue_start();
}

static int run_standard_command(const char *cmd, ptr args[], int nargs) {
  pthread_mutex_t wait = PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t *waitPtr = &wait;
  pthread_mutex_lock(waitPtr);

  __block int r;
  
  work_queue_submit(^{
      Sactivate_thread();
      ptr arglist = Snil;
      for (int i = nargs - 1; i >= 0; i--) {
	arglist = Scons(args[i], arglist);
      }

      arglist = Scons(Sstring_to_symbol(cmd), arglist);
      arglist = Scons(client_place_channel, Scons(arglist, Snil));

      racket_apply(place_channel_put, arglist);

      ptr result = racket_apply(place_channel_get, Scons(client_place_channel, Snil));
      result = Scar(result);
      if (!Sfixnump(result)) {
	r = -1;
      } else {
	r = Sinteger_value(result);
      }

      pthread_mutex_unlock(waitPtr);
    });
  pthread_mutex_lock(waitPtr);
  pthread_mutex_unlock(waitPtr);

  return r;
}

int red_client_test_call() {
  return run_standard_command("test-dispatch", NULL, 0);
}
			       
static const char *current_renderer = NULL;

static inline int synchronous_call(msgpack_object *deserialized) {
//    const char blah[256] = "hello";
//    int result = zmq_send(requester, blah, 5, ZMQ_DONTWAIT);
  printf("Sending %zu bytes\n", sbuf.size);
  int nbytes = zmq_send(requester, sbuf.data, sbuf.size, 0);
  printf("Sent %zu bytes\n", sbuf.size);
  if (nbytes == -1) {
    perror(__func__);
    return errno;
  }

  nbytes = zmq_recv(requester, recvbuf, MAX_RECV_SIZE, 0);
  if (nbytes == -1) {
    return errno;
  }

  msgpack_zone_clear(&mempool);
  msgpack_unpack_return unpack_result = msgpack_unpack(recvbuf, nbytes, NULL, &mempool, deserialized);
  if (unpack_result != MSGPACK_UNPACK_SUCCESS) {
    return -1;
  }

  return 0;
}

static inline int get_remote_status(msgpack_object *obj, bool *valid) {
  switch (obj->type) {
  case MSGPACK_OBJECT_POSITIVE_INTEGER:
    if (obj->via.u64 > INT_MAX) {
      *valid = false;
      return -1;
    }
    *valid = true;
    return (int)obj->via.u64;
  case MSGPACK_OBJECT_NEGATIVE_INTEGER:
    if (obj->via.i64 < INT_MIN) {
      *valid = false;
      return -1;
    }
    *valid = true;
    return obj->via.i64;
  default:
    *valid = false;
    return -1;
  }
}

static int simple_remote_get_status(const char *func, const char *cmdname) {
  msgpack_object deserialized;
  int result = synchronous_call(&deserialized);
  if (result != 0) {
    printf("%s: Synchronous call to %s failed\n", func, cmdname);
    return -1;
  }

  bool valid;
  result = get_remote_status(&deserialized, &valid);
  if (!valid) {
    printf("%s: %s remote status invalid\n", func, cmdname);
    return -1;
  }

  if (result != 0) {
    printf("%s: %s failed\n", func, cmdname);
    return result;
  }

  printf("%s: %s succeeded\n", func, cmdname);
  return 0;
}

static inline int64_t get_remote_id(msgpack_object *obj) {
  switch (obj->type) {
  case MSGPACK_OBJECT_POSITIVE_INTEGER:
    return (int64_t)obj->via.u64;
  case MSGPACK_OBJECT_NEGATIVE_INTEGER:
    return obj->via.i64;
  default:
    return -1;
  }
}

static uint64_t simple_remote_get_id(const char *func, const char *cmdname) {
  msgpack_object deserialized;
  int result = synchronous_call(&deserialized);
  if (result != 0) {
    printf("%s: Synchronous call to %s failed\n", func, cmdname);
    return -1;
  }

  int64_t id = get_remote_id(&deserialized);

  if (id < 0) {
    printf("%s: %s failed\n", func, cmdname);
    return -1;
  }
  
  printf("%s: %s succeeded\n", func, cmdname);
  return id;  
}

int mm_client_backend_attach_shared_memory(const char *path, size_t size, remote_shm_id_t *outid) {
  
  const char *cmd = "attach-shared-memory";
  msgpack_sbuffer_clear(&sbuf);
  msgpack_pack_str_with_body(&pk, cmd, strlen(cmd));
  msgpack_pack_array(&pk, 2);
  msgpack_pack_str_with_body(&pk, path, strlen(path));
  msgpack_pack_uint64(&pk, size);

  msgpack_object deserialized;
  int result = synchronous_call(&deserialized);
  if (result != 0) {
    printf("%s: Synchronous call to %s failed\n", __func__, cmd);
    return -1;
  }

  int id = get_remote_id(&deserialized);
  if (id == -1) return -1;
  
  if (outid) *outid = id;

  return 0;
}

int mm_client_detach_shared_memory(remote_shm_id_t id) {
  const char *cmd = "detach-shared-memory";
  msgpack_sbuffer_clear(&sbuf);
  msgpack_pack_str_with_body(&pk, cmd, strlen(cmd));
  msgpack_pack_array(&pk, 1);
  msgpack_pack_uint64(&pk, id);

  int result = simple_remote_get_status(__func__, cmd);
  if (result != 0) {
    return -1;
  }

  return 0;
}

int mm_client_draw_buffer_in_portal(remote_buffer_id_t bufid, remote_portal_id_t pid) {
  const char *cmd = "draw-buffer-in-portal";
  msgpack_sbuffer_clear(&sbuf);
  msgpack_pack_str_with_body(&pk, cmd, strlen(cmd));
  msgpack_pack_array(&pk, 2);
  msgpack_pack_uint64(&pk, bufid);
  msgpack_pack_uint64(&pk, pid);

  int result = simple_remote_get_status(__func__, cmd);
  if (result != 0) {
    return -1;
  }

  return 0;
}

int mm_client_open_portal(remote_shm_id_t shmid, int width, int height, remote_portal_id_t *outid) {

  const char *cmd = "open-portal";
  msgpack_sbuffer_clear(&sbuf);
  msgpack_pack_str_with_body(&pk, cmd, strlen(cmd));
  msgpack_pack_array(&pk, 3);
  msgpack_pack_uint64(&pk, shmid);
  msgpack_pack_int32(&pk, width);
  msgpack_pack_int32(&pk, height);

  msgpack_object deserialized;
  int result = synchronous_call(&deserialized);
  if (result != 0) {
    printf("%s: Synchronous call to %s failed\n", __func__, cmd);
    return -1;
  }

  int id = get_remote_id(&deserialized);
  if (id == -1) return -1;

  if (outid) *outid = id;

  return 0;
}

int mm_client_close_portal(remote_portal_id_t pid) {
  const char *cmd = "close-portal";
  msgpack_sbuffer_clear(&sbuf);
  msgpack_pack_str_with_body(&pk, cmd, strlen(cmd));
  msgpack_pack_array(&pk, 1);
  msgpack_pack_uint64(&pk, pid);

  int result = simple_remote_get_status(__func__, cmd);
  if (result != 0) {
    return -1;
  }

  return 0;
}
					       
int mm_client_backend_load_renderer(const char *renderer) {
  if (current_renderer != NULL) {
    if (strcmp(renderer, current_renderer) == 0) {
      return 0;
    }
  }

  const char *cmd = "backend-load-renderer";
  msgpack_sbuffer_clear(&sbuf);
  msgpack_pack_str_with_body(&pk, cmd, strlen(cmd));
  msgpack_pack_array(&pk, 1);
  int len = strlen(renderer);
  msgpack_pack_str(&pk, len);
  msgpack_pack_str_body(&pk, renderer, len);

  int result = simple_remote_get_status(__func__, cmd);
  if (result != 0) {
    return -1;
  }

  current_renderer = renderer;  
  return 0;
}

remote_buffer_id_t mm_client_backend_load_file(const char *filename) {
  const char *cmd = "load-file";
  msgpack_sbuffer_clear(&sbuf);
  msgpack_pack_str_with_body(&pk, cmd, strlen(cmd));
  msgpack_pack_array(&pk, 1);
  int len = strlen(filename);
  msgpack_pack_str(&pk, len);
  msgpack_pack_str_body(&pk, filename, len);

  int result = simple_remote_get_id(__func__, cmd);
  if (result != 0) {
    return -1;
  }

  return 0;
}

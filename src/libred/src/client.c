#include <assert.h>
#include <zmq.h>
#include <msgpack.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>

#include "client.h"

static void *ctx;
static void *requester;

static msgpack_sbuffer sbuf;
static msgpack_packer pk;
static msgpack_zone mempool;

#define MAX_RECV_SIZE 4096
static char recvbuf[MAX_RECV_SIZE];

#define REMOTE_STATUS_MIN INT_MIN
#define REMOTE_STATUS_MAX INT_MAX

int mm_client_init(const char *socketfn) {
  /* requester = zmq_socket(shared_ctx, ZMQ_REQ); */
  /* int status = zmq_connect (requester, "inproc://dispatch"); */
  /* if (status != 0) { */
  /*   return status; */
  /* } */

  ctx = zmq_init(1);
  assert(ctx);
  requester = zmq_socket(ctx, ZMQ_REQ);
  assert(requester);
  printf("Connecting socket %s\n", socketfn);
  zmq_connect(requester, socketfn);

  /* char blah[256]; */
  /* int result = zmq_recv(requester, blah, 256, 0); */

  msgpack_sbuffer_init(&sbuf);
  msgpack_packer_init(&pk, &sbuf, msgpack_sbuffer_write);
  msgpack_zone_init(&mempool, 4096);

  printf("Initialized client\n");
  
  return 0;
}

/*
void mm_try_client() {
  assert(ctx != NULL);
  void *requester = zmq_socket(ctx, ZMQ_REQ);
  zmq_connect (requester, "inproc://dispatch");
  int request_nbr;
  for (request_nbr = 0; request_nbr != 10; request_nbr++) {
    char buffer [10];
    printf ("Sending Hello %d…\n", request_nbr);
    zmq_send (requester, "Hello", 5, 0);
    zmq_recv (requester, buffer, 10, 0);
    buffer[9] = '\0';
    printf ("Received World %d (%s)\n", request_nbr, buffer);
  }
}
*/

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

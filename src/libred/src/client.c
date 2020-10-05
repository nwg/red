#include <assert.h>
#include <zmq.h>
#include <msgpack.h>
#include <string.h>
#include <stdbool.h>

#include "client.h"

static void *requester;

static msgpack_sbuffer sbuf;
static msgpack_packer pk;
static msgpack_zone mempool;

#define MAX_RECV_SIZE 4096
static char recvbuf[MAX_RECV_SIZE];

#define REMOTE_STATUS_MIN INT_MIN
#define REMOTE_STATUS_MAX INT_MAX

int mm_client_init(void *shared_ctx) {
  requester = zmq_socket(shared_ctx, ZMQ_REQ);
  int status = zmq_connect (requester, "inproc://dispatch");
  if (status == 0) {
    return 0;
  }

  msgpack_sbuffer_init(&sbuf);
  msgpack_packer_init(&pk, &sbuf, msgpack_sbuffer_write);
  msgpack_zone_init(&mempool, 4096);
  
  return status;
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

static void unload_current_renderer() {
  assert(current_renderer != NULL);

  current_renderer = NULL;
}

static inline void pack_str(const char *str) {
  int len = strlen(str);
  msgpack_pack_str(&pk, len);
  msgpack_pack_str_body(&pk, str, len);  
}

static inline int synchronous_call(msgpack_object *deserialized) {
  int result = zmq_send(requester, sbuf.data, sbuf.size, 0);
  if (result != 0) {
    return result;
  }

  int nbytes = zmq_recv(requester, recvbuf, MAX_RECV_SIZE, 0);
  if (nbytes == -1) {
    return -1;
  }

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

int mm_backend_load_renderer(const char *renderer) {
  if (current_renderer != NULL) {
    if (strcmp(renderer, current_renderer) == 0) {
      return 0;
    }
  }

  pack_str("backend-load-renderer");
  msgpack_pack_array(&pk, 1);
  int len = strlen(renderer);
  msgpack_pack_str(&pk, len);
  msgpack_pack_str_body(&pk, renderer, len);

  msgpack_object deserialized;
  int result = synchronous_call(&deserialized);
  if (result != 0) {
    printf("%s: Synchronous call to backend-load-renderer failed\n", __func__);
    return -1;
  }

  bool valid;
  result = get_remote_status(&deserialized, &valid);
  if (!valid) {
    printf("%s: backend-load-renderer remote status invalid\n", __func__);
    return -1;
  }

  if (result != 0) {
    printf("%s: backend-load-renderer failed\n", __func__);
    return result;
  }

  current_renderer = renderer;  
  return 0;
}


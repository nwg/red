#include <stdio.h>
#include <libfswatch/c/libfswatch.h>

#include "libred.h"
#include "client.h"

int libred_init(const char *client_socket_fn) {
  FSW_STATUS ret = fsw_init_library();
  if (ret != FSW_OK) {
    return -1;
  }

  printf("libred_init\n");
  return mm_client_init(client_socket_fn);
}

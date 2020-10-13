#include <stdio.h>
#include <sys/mman.h>

#include "libred.h"
#include "client.h"

int libred_init(const char *client_socket_fn) {
  printf("libred_init\n");
  return mm_client_init(client_socket_fn);
}

int libred_load_file(const char *fn) {
  return 0;
}

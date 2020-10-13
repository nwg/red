#ifndef __LIBRED_H__
#define __LIBRED_H__

#define LIBRED_EXPORT __attribute__((visibility("default")))

LIBRED_EXPORT int libred_init(const char *client_socket_fn);

#endif

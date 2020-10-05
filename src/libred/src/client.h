#ifndef __LIBRED_CLIENT_H__
#define __LIBRED_CLIENT_H__

#include "libred.h"

LIBRED_EXPORT int mm_client_init(void *shared_ctx);
LIBRED_EXPORT int mm_client_backend_load_renderer(const char *renderer);

#endif

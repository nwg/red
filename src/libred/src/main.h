#ifndef __MAIN_H__
#define __MAIN_H__

#define LIBRED_EXPORT __attribute__((visibility("default")))

LIBRED_EXPORT int libred_init(const char *execname, const char *petite, const char *scheme, const char *racket);

LIBRED_EXPORT __attribute__((noreturn)) void libred_run(void);
LIBRED_EXPORT int libred_test(void);

#endif

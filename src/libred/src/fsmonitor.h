#ifndef __FS_MONITOR_H__
#define __FS_MONITOR_H__

/* typedef void(* fs_monitor_callback_t) (const char *path, void *data); */

typedef void (^fs_monitor_callback_t) (void);

int fs_start_watching_file(const char *path, fs_monitor_callback_t callback);
int fs_stop_watching_file();

#endif

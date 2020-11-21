#ifndef __WORK_QUEUE_H__
#define __WORK_QUEUE_H__

typedef void (^workBlock)(void);

int work_queue_init();
__attribute__((noreturn)) void work_queue_start();
int work_queue_submit(workBlock blk);

#endif

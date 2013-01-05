#ifndef CPROCESS_H
#define CPROCESS_H

#if (USE_SCHED_YIELD)
#include <sched.h>
#define CSCHED_YIELD()  sched_yield()
#else
#define CSCHED_YIELD()  usleep(1)
#endif

#ifndef CPU_NUM
#define CPU_NUM 2 //normal cpu is 2.
#endif

#if( __i386__ || __i386 || __amd64__ || __amd64 )
#define CPU_PAUSE() __asm__("pause")
#else
#define CPU_PAUSE()
#endif

#endif /*end define common process*/
#ifndef CEVENT_H
#define CEVENT_H

#include "common.h"
#include "cqueue.h"
#include "spinlock.h"

#define MAX_EVENTS (1024*6)
#define CEV_NONE 0x1
#define CEV_READ 0x1
#define CEV_WRITE 0x1<<1

typedef ssize_t event_proc(void *buf, size_t count);

typedef struct {
	int mask;
	event_proc *read;
	event_proc *write;
} cevent;

typedef struct {
	int mask;
	int fd;
} cevent_fired;

typedef struct {
	int maxfd;
	cevent *events; //should be MAX_EVENTS
	cqueue *fired_queue;
	spinlock_t fired_lock;
	void *priv_data; //use for implement data.
} cevents;

cevents *create_cevents();
void destory_cevents(cevents *cevts);
int cevents_add_event(cevents *cevts, int fd, int mask, event_proc *proc);
int cevents_del_event(cevents *cevts, int fd, int mask);
int cevents_poll(cevents *cevts, msec_t ms);
void cevents_push_fired(cevents *cevts, cevent_fired *fired);
cevent_fired *cevents_pop_fired(cevents *cevts);


#endif /*end define cevent**/

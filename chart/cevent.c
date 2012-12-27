#include <stdlib.h>
#include <string.h>
#include "cevent.h"
#include "jmalloc.h"

cevent *create_cevents() {
	cevents *cevts;
	int len;
	len = sizeof(cevents);
	evts = (cevents *)jmalloc(len);
	memset((void *)evts, len, 0);
	evts.events = jmalloc(sizeof(cevent) * MAX_EVENTS);
	evts.fired = jmalloc(sizeof(cevent_fired) * MAX_EVENTS);
	return evts;
}

void destory_cevents(cevents *cevts) {
	if(cevts == NULL)
		return;
	if(cevts->events != NULL)
		jfree(cevts->events);
	if(cevts->fired != NULL)
		jfree(cevts->fired);
	cevts->events = NULL;
	cevts->fired = NULL;
	jfree(cevts);
}

void cevents_add_event(cevents *cevts, int fd, int mask, event_proc *proc) {
	if(fd > MAX_EVENTS)
		return -1; //TODO: change to error code
	cevent *evt = &cevts->events[fd];
	if(mask & CEV_READ) evt->read = proc;
	if(mask & CEV_WRITE) evt->write = proc;
	evt->mask |= mask;
}

void cevents_del_event(cevents *cevts, int fd, int mask) {
	size_t j;
	if(fd > MAX_EVENTS)
		return -1; //TODO: change to error code
	cevent *evt = &cevts->events[fd];
	if(mask & CEV_READ) evt->read = NULL;
	if(mask & CEV_WRITE) evt->write = NULL;
	evt->mask &= ~mask; //remove mask
	//change maxfd
	if(cevts->maxfd && evt->mask == CEV_NONE) {
		for(j = cevts->maxfd - 1; j>= 0; j--) {
			if(cevts->events[j].mask != CEV_NONE)
				cevts.maxfd = j;
		}
	}
}
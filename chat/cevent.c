#include <stdlib.h>
#include <string.h>
#include "cevent.h"
#include "jmalloc.h"
#include "code.h"

static int cevents_add_event_impl(cevents *cevts, int fd, int mask);
static int cevents_del_event_impl(cevents *cevts, int fd, int mask);
static int cevents_poll_impl(cevents *cevts);

void cevents_push_fired(cevents *cevts, cevent_fired *fired) {
	spinlock_lock(&cevts->fired_lock);
	cqueue_push(cevts->fired_queue, (void*)fired);
	spinlock_unlock(&cevts->fired_lock);
}

cevent_fired *cevents_pop_fired(cevents *cevts) {
	cevent_fired *fevt;
	spinlock_lock(&cevts->fired_lock);
	fevt = (cevent_fired*)cqueue_pop(cevts->fired_queue);
	spinlock_unlock(&cevts->fired_lock);
	return fevt;
}

cevent *create_cevents() {
	cevents *cevts;
	int len;
	len = sizeof(cevents);
	evts = (cevents *)jmalloc(len);
	memset((void *)evts, len, 0);
	evts.events = jmalloc(sizeof(cevent) * MAX_EVENTS);
	evts.fired_queue = create_cqueue();
	evnts.fired_lock = SL_UNLOCK;
	return evts;
}

void destory_cevents(cevents *cevts) {
	if(cevts == NULL)
		return;
	if(cevts->events != NULL)
		jfree(cevts->events);
	if(cevts->fired != NULL)
		destory_cqueue(cevts->fired);
	cevts->fired_lock = SL_UNLOCK;
	cevts->events = NULL;
	cevts->fired = NULL;
	jfree(cevts);
}

int cevents_add_event(cevents *cevts, int fd, int mask, event_proc *proc) {
	int ret;
	if(fd > MAX_EVENTS)
		return J_ERR;
	if(!(ret = cevents_add_event_impl(cevts, fd, mask)))
		return ret;
	cevent *evt = &cevts->events[fd];
	if(mask & CEV_READ) evt->read = proc;
	if(mask & CEV_WRITE) evt->write = proc;
	evt->mask |= mask;
	return J_OK;
}

int cevents_del_event(cevents *cevts, int fd, int mask) {
	size_t j;
	if(fd > MAX_EVENTS)
		return J_ERR; //TODO: change to error code
	cevent *evt = &cevts->events[fd];
	//don't unbind the method, maybe should be used again.
	//if(mask & CEV_READ) evt->read = NULL;
	//if(mask & CEV_WRITE) evt->write = NULL;
	evt->mask &= ~mask; //remove mask
	
	//change maxfd
	if(cevts->maxfd && evt->mask == CEV_NONE) {
		for(j = cevts->maxfd - 1; j>= 0; j--) {
			if(cevts->events[j].mask != CEV_NONE)
				cevts.maxfd = j;
		}
	}
	return cevents_del_event_impl(cevts, fd, mask);
}

//return J_OK or J_ERR
int cevents_poll(cevent *cevts) {
	int ret;
	if(cevts == NULL) {
		fprintf(stderr, "can't be happend\n");
		abort();
	}
	ret = cevents_poll_impl(cevts);
	if(ret == J_ERR)
		return J_ERR;
	return J_OK;
}

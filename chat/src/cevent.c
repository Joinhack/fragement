#include <stdio.h>
#include <string.h>
#include "cevent.h"
#include "jmalloc.h"
#include "code.h"

static int cevents_create_priv_impl(cevents *cevts);
static int cevents_destory_priv_impl(cevents *cevts);
static int cevents_add_event_impl(cevents *cevts, int fd, int mask);
static int cevents_del_event_impl(cevents *cevts, int fd, int mask);
static int cevents_poll_impl(cevents *cevts, msec_t ms);

#ifdef USE_EPOLL
#include "cevent_epoll.c"
#else
#include "cevent_select.c"
#endif

int master_fired_event_proc(cevents *cevts, cevent_fired *fired) {
	int fd = fired->fd;
	int mask = fired->mask;
	cevent *evt = &cevts->events[fd];
	if(mask & CEV_MASTER)
			return evt->master_proc(cevts, fd, evt->priv, mask);
	return 0;
}

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

cevents *create_cevents() {
	cevents *evts;
	int len;
	len = sizeof(cevents);
	evts = (cevents *)jmalloc(len);
	memset((void *)evts, len, 0);
	evts->events = jmalloc(sizeof(cevent) * MAX_EVENTS);
	evts->fired_queue = create_cqueue();
	evts->fired_lock = SL_UNLOCK;
	cevents_create_priv_impl(evts);
	return evts;
}

void destory_cevents(cevents *cevts) {
	if(cevts == NULL)
		return;
	if(cevts->events != NULL)
		jfree(cevts->events);
	if(cevts->fired_queue != NULL)
		destory_cqueue(cevts->fired_queue);
	cevts->fired_lock = SL_UNLOCK;
	cevts->events = NULL;
	cevts->fired_queue = NULL;
	cevents_destory_priv_impl(cevts);
	jfree(cevts);
}

int cevents_add_event(cevents *cevts, int fd, int mask, event_proc *proc, void *priv) {
	int ret;
	cevent *evt;
	if(fd > MAX_EVENTS)
		return J_ERR;
	evt = &cevts->events[fd];
	//this is spec process.
	if(mask & CEV_MASTER) {
		evt->mask |= mask;
		evt->master_proc = proc;
		return J_OK;
	}
	if(!(ret = cevents_add_event_impl(cevts, fd, mask)))
		return ret;
	if(mask & CEV_READ) evt->read_proc = proc;
	if(mask & CEV_WRITE) evt->write_proc = proc;
	evt->priv = priv;
	evt->mask |= mask;
	return J_OK;
}

int cevents_del_event(cevents *cevts, int fd, int mask) {
	size_t j;
	if(fd > MAX_EVENTS)
		return J_ERR;
	cevent *evt = &cevts->events[fd];
	//don't unbind the method, maybe should be used again.
	if(mask & CEV_READ) evt->read_proc = NULL;
	if(mask & CEV_WRITE) evt->write_proc = NULL;
	evt->mask &= ~mask; //remove mask
	
	//change maxfd
	if(cevts->maxfd && evt->mask == CEV_NONE) {
		for(j = cevts->maxfd - 1; j>= 0; j--) {
			if(cevts->events[j].mask != CEV_NONE)
				cevts->maxfd = j;
		}
	}
	return cevents_del_event_impl(cevts, fd, mask);
}

int cevents_enable_event(cevents *cevts, int fd, int mask) {
	return cevents_add_event_impl(cevts, fd, mask);
}

int cevents_disable_event(cevents *cevts, int fd, int mask) {
	return cevents_del_event_impl(cevts, fd, mask);
}

//return J_OK or J_ERR
int cevents_poll(cevents *cevts, msec_t ms) {
	int ret;
	if(cevts == NULL) {
		fprintf(stderr, "can't be happend\n");
		abort();
	}
	ret = cevents_poll_impl(cevts, ms);
	if(ret == J_ERR)
		return J_ERR;
	return J_OK;
}

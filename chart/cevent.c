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
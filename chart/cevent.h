#ifndef CEVENT_H
#define CEVENT_H

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
	cevent_fired *fired; //should be MAX_EVENTS
	void *priv_data; //use for implement data.
} cevents;

cevent *create_cevents();
void destory_cevents(cevents *cevts);
int cevents_add_event(cevents *cevts, int fd, int mask, event_proc *proc);
int cevents_del_event(cevents *cevts, int fd, int mask);
size_t cevents_poll(cevent *cevts);


#endif /*end define cevent**/

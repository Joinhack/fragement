#ifndef __CEVENT_H
#define __CEVENT_H

#define MAX_EVENTS (1024*6)
#define CEV_NONE 0x1
#define CEV_READ 0x1
#define CEV_WRITE 0x1<<1

typedef int read_proc(void *buf, size_t count);
typedef int write_proc(void *buf, size_t count);

typedef struct _cevent {
	int mask;
	read_proc *read;
	write_proc *write;
} cevent;

typedef struct _cevent_fired {
	int mask;
	int fd;
} cevent_fired;

typedef struct _cevents {
	int maxfd;
	cevent *events; //should be MAX_EVENTS
	cevent_fired *fired; //should be MAX_EVENTS
	void *priv_data; //use for implement data.
} cevents;

cevent *create_cevents();
void destory_cevents(cevents *cevts);



#endif /*end define cevent**/

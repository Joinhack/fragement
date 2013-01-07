#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "code.h"
#include "cevent.h"
#include "cnet.h"
#include "cio.h"
#include "network.h"
#include "jmalloc.h"

typedef struct {
	int in_fd;
	int un_fd;
	cevents *evts;
} server;


int create_tcp_server() {
	int fd;
	char buff[1024];
	fd = cnet_tcp_server("0.0.0.0", 8088, buff, sizeof(buff));
	if(fd < 0) {
		fprintf(stderr, "%s\n", buff);
		return -1;
	}
	cio_set_noblock(fd);
	return fd;
}

static void destory_server(server *svr) {
}

static server *create_server() {
	server *svr;
	svr = jmalloc(sizeof(server));
	memset(svr, 0, sizeof(server));
	svr->in_fd = create_tcp_server();
	if(svr->in_fd < 0) {
		destory_server(svr);
		return NULL;
	}
	svr->evts = create_cevents();
	return svr;
}

int server_init(server *svr) {
	cevents_add_event(svr->evts, svr->in_fd, CEV_MASTER|CEV_READ, tcp_accept_event_proc, svr);
	return 0;
}

int mainLoop(server *svr) {
	for(;;) {
		cevents_poll(svr->evts, 10);
	}
	return 0;
}


int main(int argc, char const *argv[]) {
	server *svr;
	svr = create_server();
	server_init(svr);
	mainLoop(svr);
	return 0;
}
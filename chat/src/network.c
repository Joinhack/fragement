#include <stdio.h>
#include <string.h>
#include "cevent.h"
#include "cnet.h"
#include "cio.h"

//always return 0, don't push fired event queue
int tcp_accept_event_proc(cevents *cevts, int fd, void *priv, int mask) {
	char buff[2048];
	char ip[24];
	int port;
	int clifd;
	memset(buff, 0, sizeof(buff));
	memset(ip, 0, sizeof(ip));
	if((clifd = cnet_tcp_accept(fd, ip, &port, buff, sizeof(buff))) < 0) {
		fprintf(stderr, "%s\n", buff);
	}
	//TODO: create connection
	cio_write(clifd, "aa\n", 3);
	close(clifd);
	return 0;
}

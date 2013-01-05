#include <stdio.h>
#include <stdarg.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include "cnet.h"

static set_err(char *err, size_t len, const char *fmt, ...) {
	va_list list;
	va_start(list, fmt);
	vsnprintf(err, len, fmt, list);
	va_end(list);
}

static int cnet_accept_impl(int fd, struct sockaddr *sa, socklen_t *len,char *ebuf, size_t ebuflen) {
	int fd;
	while(1) {
		fd = accept(fd, sa, len);
		if(ret == -1) {
			if(errno == EINTR)
				continue;
			else
				set_err(err, len, "%s\n", strerror(errno));
		}
		return fd;
	}
}

int cnet_tcp_accept(int fd, uint32_t *ip, int *port, char *ebuf, size_t len) {
	
}

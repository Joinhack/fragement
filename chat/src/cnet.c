#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "cnet.h"

static cnet_fmt_err(char *err, size_t len, const char *fmt, ...) {
	va_list list;
	va_start(list, fmt);
	vsnprintf(err, len, fmt, list);
	va_end(list);
}

static int cnet_accept_impl(int fd, struct sockaddr *sa, socklen_t *len,char *ebuf, size_t ebuflen) {
	int clifd;
	while(1) {
		clifd = accept(fd, sa, len);
		if(clifd == -1) {
			if(errno == EINTR)
				continue;
			else {
				cnet_fmt_err(ebuf, len, "accept error: %s\n", strerror(errno));
				return -1;
			}
		}
		return clifd;
	}
}

static int cnet_bind_listen(int fd, struct sockaddr *sa, socklen_t slen,  char *ebuf, size_t len) {
	int ret;
	if(bind(fd, sa, slen) < 0) {
		cnet_fmt_err(ebuf, len, "bind error: %s\n", strerror(errno));
		return -1;
	}
	if(listen(fd, 511) < 0) {
		cnet_fmt_err(ebuf, len, "listen error: %s\n", strerror(errno));
		return -1;
	}
	return 0;
}

int cnet_tcp_accept(int fd, char *ip, int *port, char *ebuf, size_t len) {
	struct sockaddr_in sa;
	socklen_t slen;
	int ret;
	ret = cnet_accept_impl(fd, (struct sockaddr*)&sa, &slen);
	if (port) *port = ntohs(sa.sin_port);
	if (ip) strcpy(ip,inet_ntoa(sa.sin_addr));
	return ret;
}

int cnet_unix_accept(int fd, char *ebuf, size_t len) {
	struct sockaddr_un sa;
	socklen_t slen = sizeof(sa);
	return cnet_accept_impl(fd, (struct sockaddr*)&sa, &slen);
}

int cnet_create_sock(int domain, int type, char *ebuf, size_t len) {
	int fd, on = 1;
	fd = socket(domain, type, 0);
	if(fd < 0) {
		cnet_fmt_err(ebuf, len, "socket create error: %s\n", strerror(errno));
		return -1;
	}
	if(setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on)) == -1) {
		cnet_fmt_err(ebuf, len, "socket set reuse error: %s\n", strerror(errno));
		close(fd);
		return -1;
	}
	return fd;
}

int cnet_tcp_server(char *ip, int port, char *ebuf, size_t len) {
	int fd;
	struct sockaddr_in sa;

	memset(&sa, sizeof(sa), 0);
	sa.sin_family = AF_INET;
	sa.sin_port = htons(port);
	sa.sin_addr.s_addr = htonl(inet_addr(ip));
	if((fd = cnet_create_sock(AF_INET, SOCK_STREAM, ebuf, len)) < 0)
		return fd;
	if(cnet_bind_listen(fd, &sa, sizeof(sa), ebuf, len) < 0) {
		close(fd);
		return -1;
	}
	return fd;
}

int cnet_unix_server(char *path, mode_t perm,char *ebuf, size_t len) {
	struct sockaddr_un sa;
	memset(&sa, sizeof(sa), 0);
	sa.sun_family = AF_LOCAL;
	strncpy(sa.sun_path, path, sizeof(sa.sun_path)-1);
	if(cnet_bind_listen(fd, &sa, sizeof(sa), ebuf, len) < 0) {
		close(fd);
		return -1;
	}
	if(fchmod(fd, mode) < 0) {
		cnet_fmt_err(ebuf, len, "socket set reuse error: %s\n", strerror(errno));
		close(fd);
		return -1;
	}
	return fd;
}



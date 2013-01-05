#ifndef CNET_H
#define CNET_H

#include "common.h"

int cnet_tcp_accept(int fd, uint32_t *ip, int *port, char *ebuf, size_t len);

#endif /*end define cnet*/

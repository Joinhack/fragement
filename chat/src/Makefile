CC = gcc
OPTS =  -DUSE_EPOLL

server:
	$(CC) -o server server.c cnet.c  cqueue.c cevent.c jmalloc.c cio.c  network.c spinlock.c $(OPTS) 
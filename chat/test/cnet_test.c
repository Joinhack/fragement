#include <stdio.h>
#include <cnet.h>

int main(int argc, char const *argv[]) {
	int fd;
	int clifd;
	char buff[1024];
	fd = cnet_tcp_server("192.168.1.3", 19999, buff, sizeof(buff));
	if(fd < 0) {
		printf("%s\n", buff);
		return -1;
	}
	while(1) {
		clifd = cnet_tcp_accept(fd, NULL, NULL, buff, sizeof(buff));
		printf("%s\n", buff);
		write(clifd, "1", 1);
		close();
	}
	return 0;
}

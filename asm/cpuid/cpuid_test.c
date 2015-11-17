#include <stdio.h>
#include <string.h>

extern void cpuid(char *buf);

int main() {
	char buf[32];
	memset(buf, 0, sizeof(buf));
	cpuid(buf);
	printf("%s", buf);
	return 0;
}
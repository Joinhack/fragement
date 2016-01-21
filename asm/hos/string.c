#include "kernel.h"

void memset(void* p, u32 c, u32 len) {
	int i;
	char *o = (char*)p;
	for(i = 0; i < len; i++)
		*o = c;
}

char* l2str(char* buf, int len, long n) {
	char *ptr = buf + len - 1;
	if(!len) return NULL;
	*(ptr--) = 0;
	u8 l;
	while(n && len) {
		l = n%10;
		n /= 10;
		*(ptr--) = l+'0';
	}
	return ptr+1;
}
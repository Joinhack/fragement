#include "kernel.h"

u32 tick = 0;
void print_tick() {
	char buf[16] = {0};
	char *ptr = buf + sizeof(buf) - 1;
	u32 left = tick;
	u8 l;
	do {
		l = left%10;
		left /= 10;
		*(ptr--) = l+'0';
	} while(left);
	puts("ticks:");
	puts(ptr+1);
	puts("\n");
	tick++;
}

void __entry kentry() {
	screen_clear();
	puts("kernel is starting...\n");
	reinstall_idt();
	set_irq_handle(1, print_tick);
	while(1);
}

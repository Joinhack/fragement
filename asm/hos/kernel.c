#include "kernel.h"

u32 tick = 0;
void print_tick() {
	char buf[16] = {0};
	//puts("ticks:");
	//puts(l2str(buf, sizeof(buf), tick));
	//puts("\n");
	tick++;
}

extern u32 __end;

void __entry kentry() {
	screen_clear();
	puts("kernel is starting...\n");
	reinstall_idt();
	set_irq_handle(8, print_tick);
	init_mmu();
	while(1);
}

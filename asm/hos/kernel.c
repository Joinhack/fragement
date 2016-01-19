#include "kernel.h"

void __entry kentry() {
	screen_clear();
	puts("kernel is starting...\n");
	reinstall_idt();
	
	while(1);
}

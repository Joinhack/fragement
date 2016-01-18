#include "kernel.h"

extern u32 __end;

static gate_way gateway[256];

static struct desc_struct gdt[3];

void reinstall_idt() {
	static const struct gdt_ptr idt_tables = {sizeof(gateway), (u32)gateway};
	asm volatile("lidtl %0\n" : : "m" (idt_tables));
}


void __entry kentry() {
	reinstall_idt();
	while(1);
}

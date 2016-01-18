#include "kernel.h"

extern u32 __end;

static gate_way gateway[256];

static struct desc_struct gdt[3];

void reinstall_idt() {
	static const struct gdt_ptr idt_tables = {sizeof(gateway), (u32)gateway};
	asm volatile("lidtl %0\n" : : "m" (idt_tables));
}

void reinstall_gdt() {
	//use the same code segment and data segment define in main.
	gdt[1] = ((struct desc_struct)GDT_ENTRY_INIT(0xc09b, 0, 0xfffff));
	gdt[2] = ((struct desc_struct)GDT_ENTRY_INIT(0xc093, 0, 0xfffff));
	
	static const struct gdt_ptr gdt_tables = {sizeof(struct desc_struct), (u32)gdt};
	asm volatile(
		"lgdtl %0\n"
		"movl $(2*8), %%ecx\n"
		"movl %%ecx, %%ds\n"
		"movl %%ecx, %%ds\n"
		"movl %%ecx, %%es\n"
		"movl %%ecx, %%fs\n"
		"movl %%ecx, %%gs\n"
		:: "m" (gdt_tables));
}

void __entry kentry() {
	reinstall_idt();
	while(1);
}

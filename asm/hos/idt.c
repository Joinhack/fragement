#include "kernel.h"
extern u32 __end;

static struct gatedesc gateway[IRQLEN];

static irq_handle_t irq_handles[IRQLEN] = {0};

static void idt_set_gate(u8 num, u32 base, u16 sel, u8 flags);

void reinstall_idt() {
	int i;
	u32 len;
	u32 handler;
	static const struct gdt_ptr idt_tables = {.len=(sizeof(gateway)-1), .ptr = (u32)gateway};
	extern u32 __vectors[];
	for(i = 0; i < IRQLEN; i++) {
		SETGATE(gateway[i], 1, 0x08, __vectors[i], 0);
	}
	asm volatile ("lidtl %0\n sti\n" : : "m" (idt_tables));
}

void set_irq_handle(u32 type, irq_handle_t handle) {
	irq_handles[type] = handle;
}

void remove_irq_handle(u32 type) {
	irq_handles[type] = NULL;
}

void irq_handler(registers_t reg) {
	irq_handle_t handle = irq_handles[reg.int_no];

	if(handle) 
		handle();
	else {
		char buf[4];
		puts(l2str(buf, sizeof(buf), reg.int_no));
		puts(" : is not installed\n");
	}
  outb(0x20, 0x20);
}
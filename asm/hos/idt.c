#include "kernel.h"
extern u32 __end;

static gate_way gateway[IRQLEN];


#define idt_handle_len (idt_handler_array_end - idt_handler_array)

static void idt_set_gate(u8 num, u32 base, u16 sel, u8 flags);

void reinstall_idt() {
	int i;
	u32 len;
	u32 handler;
	static const struct gdt_ptr idt_tables = {.len=sizeof(gateway), .ptr = (u32)gateway};
	asm volatile ("mov $idt_handler_array,%0":"=r"(handler):);
	asm volatile ("mov $idt_handler_array_len,%0":"=r"(len):);
	for(i = 0; i < IRQLEN; i++) {
		idt_set_gate(i, handler + len/IRQLEN, 0x08, 0x8E);
	}
	asm volatile ("lidtl %0\n sti\n" : : "m" (idt_tables));
}

static void idt_set_gate(u8 num, u32 base, u16 sel, u8 flags) {
	register u32 l = base & 0xFFFF; 
	register u32 h = (base >> 16) & 0xFFFF;
	gateway[num].base_lo = l;
	gateway[num].base_hi = h;
	gateway[num].sel = sel;
	gateway[num].always0 = 0;
	// We must uncomment the OR below when we get to using user-mode.
	// It sets the interrupt gate's privilege level to 3.
	gateway[num].flags   = flags /* | 0x60 */;
}

void irq_handler(u32 id) {
   
}
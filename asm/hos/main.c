#include "boot.h"

extern u16 _end;

struct gdt_ptr {
	u16 len;
	u32 ptr;
} __attribute__((packed));

void install_gdt() {
	asm volatile("cli");
	static const u64 boot_gdt[] __attribute__((aligned(16))) = {
		[GDT_ENTRY_BOOT_CS] = GDT_ENTRY(0xc09b, 0, 0xfffff),
		[GDT_ENTRY_BOOT_DS] = GDT_ENTRY(0xc093, 0, 0xfffff),
	};
	static struct gdt_ptr gdtptr = {
		.len = sizeof(boot_gdt)
	};
	gdtptr.ptr = (u32)boot_gdt + (ds()<<4);
	asm volatile ("lgdtl %0\n" : : "m"(gdtptr));
}

static void enable_a20_fast(void) {
	u8 port_a;

	port_a = inb(0x92);	/* Configuration port A */
	port_a |=  0x02;	/* Enable A20 */
	port_a &= ~0x01;	/* Do not reset machine */
	outb(port_a, 0x92);
}

void install_idt() {
	static const struct gdt_ptr null_idt = {0, 0};
	asm volatile("lidtl %0" : : "m" (null_idt));
}

//can't use entry named main, will cause the stack align.
void m16entry() {
	enable_a20_fast();
	install_gdt();
	install_idt();
	realmode2protect();
}

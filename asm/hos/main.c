#include "boot.h"

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
	gdtptr.ptr = ((u32)boot_gdt) + (ds()<<4);
	asm volatile ("lgdtl %0\n" : : "m"(gdtptr));
}

void install_idt() {
	static const struct gdt_ptr null_idt = {0, 0};
	asm volatile("lidtl %0" : : "m" (null_idt));
}


void main() {
	install_gdt();
	install_idt();
	realmode2protect();
}

#include "boot.h"

struct gdt_ptr {
	u16 len;
	u32 ptr;
} __attribute__((packed));

static u32 cs() {
	u32 rs;
	asm volatile (
		"mov %%cs, %%ax\n"
		:"=a"(rs)
		:
	);
	return rs;
}


void install_gdt() {
	static const u64 boot_gdt[] __attribute__((aligned(16))) = {
		0
	};
	static struct gdt_ptr gdtptr = {
		.len = sizeof(boot_gdt)
	};
	gdtptr.ptr = (u32)boot_gdt + cs()<<4;
	asm volatile ("lgdtw %0\n" : : "m"(gdtptr));
}

void main() {
	install_gdt();
	asm volatile (
		"jmp ."
	);
}

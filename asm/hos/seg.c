#include "kernel.h"

static struct segdesc gdt[] = {
	SEG_NULL,
	[SEG_KTEXT] = SEG(STA_X | STA_R, 0x0, 0xFFFFFFFF, DPL_KERNEL),
	[SEG_KDATA] = SEG(STA_W, 0x0, 0xFFFFFFFF, DPL_KERNEL),
	[SEG_UTEXT] = SEG(STA_X | STA_R, 0x0, 0xFFFFFFFF, DPL_USER),
	[SEG_UDATA] = SEG(STA_W, 0x0, 0xFFFFFFFF, DPL_USER),
	[SEG_TSS]    = SEG_NULL,
};

void reinstall_gdt() {
	static const struct gdt_ptr gdtptr = {.len=(sizeof(gdt)-1), .ptr = (u32)gdt};
	asm volatile ("lgdt (%0)" :: "m" (gdtptr));
	asm volatile ("movw %%ax, %%gs" :: "a" (KERNEL_DS));
	asm volatile ("movw %%ax, %%fs" :: "a" (KERNEL_DS));
	asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
	asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
	asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
}

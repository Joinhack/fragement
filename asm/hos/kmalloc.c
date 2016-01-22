#include "kernel.h"

u32 memend = 0x100000;

#define PAGEALIGN 0xFFF
#define PAGEMASK 0xFFFFF000

static u32 kmalloc_alloc(u32 sz, int a, u32 *phys) {
	//if memend big than 1 page, let calc it.
	if(a && (memend&PAGEMASK)) {
		memend &= PAGEMASK;
		memend += 0x1000;
	}

	if(phys)
		*phys = memend;
	u32 p = memend;
	memend += sz;
	return p;
}

u32 kmalloc_align(u32 sz) {
	return kmalloc_alloc(sz, 1, NULL);
}

u32 kmalloc_alignp(u32 sz, u32 *phys) {
	return kmalloc_alloc(sz, 1, phys);
}

u32 kmalloc(u32 sz) {
	return kmalloc_alloc(sz, 0, NULL);
}


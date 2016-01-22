#ifndef __KMALLOC_H
#define __KMALLOC_H

u32 kmalloc_align(u32 sz);

u32 kmalloc_alignp(u32 sz, u32 *phys);

u32 kmalloc(u32 sz);

#endif
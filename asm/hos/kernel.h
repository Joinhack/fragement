#ifndef __KERNEL_H
#define __KERNEL_H
#ifndef __ASSEMBLER__

typedef signed char s8;
typedef unsigned char u8;

typedef signed short s16;
typedef unsigned short u16;

typedef signed int s32;
typedef unsigned int u32;

typedef signed long s64;
typedef unsigned long u64;

#define __entry __attribute__((section ("._textenrty")))

struct idt_entry_struct {
   u16 base_lo;             // The lower 16 bits of the address to jump to when this interrupt fires.
   u16 sel;                 // Kernel segment selector.
   u8  always0;             // This must always be zero.
   u8  flags;               // More flags. See documentation.
   u16 base_hi;             // The upper 16 bits of the address to jump to.
} __attribute__((packed));

struct gdt_ptr {
	u16 len;
	u32 ptr;
} __attribute__((packed));

typedef struct idt_entry_struct gate_way;

void reinstall_idt();

void put(char c);

void puts(char *c);

void screen_clear();

typedef void (*irq_handle_t) ();

void set_irq_handle(u32 type, irq_handle_t handle);

void remove_irq_handle(u32 type);

void init_mmu();

void memset(void* p, u32 c, u32 len);

char* l2str(char* buf, int len, long n);

#endif

#include "common.h"

#define STACKLEN (1024*1024);

#define IRQLEN 32

#define IDT_HANDLER_SIZE 9
#endif

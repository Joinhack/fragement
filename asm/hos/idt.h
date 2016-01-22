#ifndef __IDT_H
#define __IDT_H


struct gdt_ptr {
	u16 len;
	u32 ptr;
} __attribute__((packed));

typedef struct idt_entry_struct gate_way;

struct idt_entry_struct {
   u16 base_lo;             // The lower 16 bits of the address to jump to when this interrupt fires.
   u16 sel;                 // Kernel segment selector.
   u8  always0;             // This must always be zero.
   u8  flags;               // More flags. See documentation.
   u16 base_hi;             // The upper 16 bits of the address to jump to.
} __attribute__((packed));

typedef void (*irq_handle_t) ();

void reinstall_idt();

void set_irq_handle(u32 type, irq_handle_t handle);

void remove_irq_handle(u32 type);

#endif
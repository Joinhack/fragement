#ifndef __IDT_H
#define __IDT_H

#define STS_IG32        0xE            // 32-bit Interrupt Gate
#define STS_TG32        0xF            // 32-bit Trap Gate

struct gdt_ptr {
	u16 len;
	u32 ptr;
} __attribute__((packed));

typedef struct gatedesc gate_way;

typedef void (*irq_handle_t) ();

void reinstall_idt();

void set_irq_handle(u32 type, irq_handle_t handle);

void remove_irq_handle(u32 type);

typedef struct registers {
	u32 edi, esi, ebp, esp, ebx, edx, ecx, eax; // Pushed by pusha.
	u32 int_no, err_code;    // Interrupt number and error code (if applicable)
	u32 eip, cs, eflags, useresp, ss; // Pushed by the processor automatically.
} registers_t;

struct gatedesc {
	unsigned gd_off_15_0 : 16;        // low 16 bits of offset in segment
	unsigned gd_ss : 16;            // segment selector
	unsigned gd_args : 5;            // # args, 0 for interrupt/trap gates
	unsigned gd_rsv1 : 3;            // reserved(should be zero I guess)
	unsigned gd_type : 4;            // type(STS_{TG,IG32,TG32})
	unsigned gd_s : 1;                // must be 0 (system)
	unsigned gd_dpl : 2;            // descriptor(meaning new) privilege level
	unsigned gd_p : 1;                // Present
	unsigned gd_off_31_16 : 16;        // high bits of offset in segment
} __attribute__((packed));

#define SETGATE(gate, istrap, sel, off, dpl) {            \
	(gate).gd_off_15_0 = (u32)(off) & 0xffff;        \
	(gate).gd_ss = (sel);                                \
	(gate).gd_args = 0;                                    \
	(gate).gd_rsv1 = 0;                                    \
	(gate).gd_type = (istrap) ? STS_TG32 : STS_IG32;    \
	(gate).gd_s = 0;                                    \
	(gate).gd_dpl = (dpl);                                \
	(gate).gd_p = 1;                                    \
	(gate).gd_off_31_16 = (u32)(off) >> 16;        \
}

#endif
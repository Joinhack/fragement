#ifndef __SEG_H
#define __SEG_H

#define STA_X 0x8            // Executable segment
#define STA_E 0x4            // Expand down (non-executable segments)
#define STA_C 0x4            // Conforming code segment (executable only)
#define STA_W 0x2            // Writeable (non-executable segments)
#define STA_R 0x2            // Readable (executable segments)
#define STA_A 0x1   

#define SEG_NULL 0x0
#define SEG_KTEXT 0x1
#define SEG_KDATA 0x2
#define SEG_UTEXT 0x3
#define SEG_UDATA 0x4
#define SEG_TSS 0x5

#define KERNEL_DS SEG_KDATA*8

#define DPL_KERNEL  (0)
#define DPL_USER    (3)

struct segdesc {
    unsigned sd_lim_15_0 : 16;        // low bits of segment limit
    unsigned sd_base_15_0 : 16;        // low bits of segment base address
    unsigned sd_base_23_16 : 8;        // middle bits of segment base address
    unsigned sd_type : 4;            // segment type (see STS_ constants)
    unsigned sd_s : 1;                // 0 = system, 1 = application
    unsigned sd_dpl : 2;            // descriptor Privilege Level
    unsigned sd_p : 1;                // present
    unsigned sd_lim_19_16 : 4;        // high bits of segment limit
    unsigned sd_avl : 1;            // unused (available for software use)
    unsigned sd_rsv1 : 1;            // reserved
    unsigned sd_db : 1;                // 0 = 16-bit segment, 1 = 32-bit segment
    unsigned sd_g : 1;                // granularity: limit scaled by 4K when set
    unsigned sd_base_31_24 : 8;        // high bits of segment base address
};



#define SEG(type, base, lim, dpl)                        \
(struct segdesc){                                    \
    ((lim) >> 12) & 0xffff, (base) & 0xffff,        \
    ((base) >> 16) & 0xff, type, 1, dpl, 1,            \
    (unsigned)(lim) >> 28, 0, 0, 1, 1,                \
    (unsigned) (base) >> 24                            \
}

void reinstall_gdt();
#endif
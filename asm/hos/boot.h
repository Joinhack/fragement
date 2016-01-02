#ifndef __BOOT_H
#define __BOOT_H
#ifndef __ASSEMBLER__

typedef signed char s8;
typedef unsigned char u8;

typedef signed short s16;
typedef unsigned short u16;

typedef signed long s32;
typedef unsigned long u32;

typedef signed long long s64;
typedef unsigned long long u64;

inline static u32 ds() {
	u32 rs;
	asm volatile ("mov %%ds, %0\n" : "=rm"(rs));
	return rs;
}

inline static u32 ss() {
	u32 rs;
	asm volatile ("mov %%ss, %0\n" : "=rm"(rs));
	return rs;
}

inline static u32 cs() {
	u32 rs;
	asm volatile ("mov %%cs, %0\n" : "=rm"(rs));
	return rs;
}

static inline void outb(u8 v, u16 port) {
	asm volatile("outb %0,%1" : : "a" (v), "dN" (port));
}
static inline u8 inb(u16 port) {
	u8 v;
	asm volatile("inb %1,%0" : "=a" (v) : "dN" (port));
	return v;
}

static inline void outw(u16 v, u16 port) {
	asm volatile("outw %0,%1" : : "a" (v), "dN" (port));
}

static inline u16 inw(u16 port) {
	u16 v;
	asm volatile("inw %1,%0" : "=a" (v) : "dN" (port));
	return v;
}

static inline void outl(u32 v, u16 port) {
	asm volatile("outl %0,%1" : : "a" (v), "dN" (port));
}

static inline u32 inl(u16 port) {
	u32 v;
	asm volatile("inl %1,%0" : "=a" (v) : "dN" (port));
	return v;
}


#define UNIT(x, y) x##y

#define GDT_ENTRY(flags, base, limit)			\
	((((base)  & UNIT(0xff000000,ULL)) << (56-24)) |	\
	 (((flags) & UNIT(0x0000f0ff,ULL)) << 40) |	\
	 (((limit) & UNIT(0x000f0000,ULL)) << (48-16)) |	\
	 (((base)  & UNIT(0x00ffffff,ULL)) << 16) |	\
	 (((limit) & UNIT(0x0000ffff,ULL))))	

#endif

#define GDT_ENTRY_BOOT_CS	1

#define GDT_ENTRY_BOOT_DS	2

#define __BOOT_CS	(GDT_ENTRY_BOOT_CS*8)
#define __BOOT_DS	(GDT_ENTRY_BOOT_DS*8)

#endif

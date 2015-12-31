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

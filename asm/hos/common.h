#ifndef __COMMON_H
#define __COMMON_H
#ifndef __ASSEMBLER__
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
#endif
#define NULL 0
#endif //__COMMON_H

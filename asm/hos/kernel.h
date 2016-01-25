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

void put(char c);

void puts(char *c);

void screen_clear();

void init_mmu();

#include "seg.h"
#include "string.h"
#include "idt.h"
#include "kmalloc.h"

#endif

#include "common.h"

#define STACKLEN (1024*1024);

#define IRQLEN 256

#define IDT_HANDLER_SIZE 9

#define EXCEPTION_ERRCODE_MASK		0x00027d00

#endif

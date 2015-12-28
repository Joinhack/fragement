UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif


CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as
CSOURCE=$(wildcard *.c)
COBJS=$(CSOURCE:.c=.o)
OBJS=os.o $(COBJS)

CODE16GCC_CFLAGS := -m32 -Wa,code16gcc.h
REALMODE_CFLAGS	:= $(CODE16GCC_CFLAGS)

CFLAGS=$(REALMODE_CFLAGS)

all: raw.img

loader.elf: loader.o
	$(LD) -Ttext 0x7c00 -o $@ $< 

os.elf: $(OBJS)
	$(LD) -T os.ld -o $@ $(OBJS)

raw.img: os.elf loader.elf
	$(OBJCOPY) -I elf32-i386 -O binary loader.elf raw.img
	$(OBJCOPY) -I elf32-i386 -O binary os.elf os.img
	cat os.img >> raw.img

%.o: %.S
	$(CC) -c $<	

%.o: %.c
	$(CC) $(CFLAGS) -c $<		

run: raw.img
	qemu-system-i386 -fda $<

debug: raw.img
	qemu-system-i386 -s -S -monitor stdio -fda $<

clean:
	rm -f *.o *.elf *.img

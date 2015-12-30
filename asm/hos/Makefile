UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif


CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as
SETUPOBJS=os.o pmjmp.o main.o
KOBJS=kernel.o

CODE16GCC_CFLAGS := -m32 -Wa,code16gcc.h
REALMODE_CFLAGS	:= $(CODE16GCC_CFLAGS)

CFLAGS16=$(REALMODE_CFLAGS)

all: kernel.img

loader.elf: loader.o
	$(LD) -Ttext 0x7c00 -o $@ $< 

setup.elf: $(SETUPOBJS)
	$(LD) -T setup.ld -o $@ $(SETUPOBJS)

setup.img: setup.elf loader.elf
	$(OBJCOPY) -I elf32-i386 -O binary loader.elf raw.img
	$(OBJCOPY) -I elf32-i386 -O binary setup.elf setup.img
	cat setup.img >> raw.img

kernel.elf: $(KOBJS) setup.img
	./linkscript.sh
	$(LD) -T kernel.ld -o $@ $(KOBJS)

kernel.img: kernel.elf
	$(OBJCOPY) -I elf32-i386 -O binary kernel.elf kernel.img
	cat kernel.img >> raw.img

main.o: main.c
	$(CC) $(CFLAGS16) -c $<		

%.o: %.S
	$(CC) -c $<	

%.o: %.c
	$(CC) -c $<	

run: kernel.img
	qemu-system-i386 -fda raw.img

debug: kernel.img
	qemu-system-i386 -s -S -monitor stdio -fda raw.img

clean:
	rm -f *.o *.elf *.img kernel.ld

UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif

CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as
DD=dd
IMG_NAME=gdt.img

all: gdt

gdt.o: gdt.S
	$(CC) -c -N -o $@ $< 

gdt: gdt.o  
	$(LD) -e _start  -T ld.lds -o $@.elf $< 
	$(OBJCOPY)   $@.elf  -O binary $@

run: gdt
	qemu-system-i386  gdt


clean:  
	-rm ./gdt ./gdt.img ./floppy.img ./gdt.o ./gdt.elf -rf

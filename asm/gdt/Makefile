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

all: $(IMG_NAME)

gdt.o: gdt.S
	$(CC) -c -N -o $@ $< 

gdt: gdt.o  
	$(LD) -e _start  -T ld.lds -o $@.elf $< 
	$(OBJCOPY)   $@.elf  -O binary $@

$(IMG_NAME): gdt  
	$(DD) if=gdt of=$@ seek=0 count=1
	$(DD) if=/dev/zero of="$@" seek=1 count=2879


run: $(IMG_NAME)
	qemu-system-i386  $(IMG_NAME)


clean:  
	-rm ./gdt ./gdt.img ./floppy.img ./gdt.o ./gdt.elf -rf

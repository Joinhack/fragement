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
	$(CC) -c  $< 

gdt: gdt.o 
	$(LD)  -Ttext 0x7c00 -o gdt.bin gdt.o --oformat binary

run: gdt
	qemu-system-i386 gdt.bin


debug: gdt
	qemu-system-i386  gdt.bin -s -S -monitor stdio

clean:  
	-rm *.o *.bin -rf

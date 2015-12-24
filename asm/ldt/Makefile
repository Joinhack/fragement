UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif

CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as
DD=dd
IMG_NAME=ldt.img

all: ldt


ldt.o: ldt.S
	$(CC) -c  $< 

ldt: ldt.o 
	$(LD)  -Ttext 0x7c00 -o ldt.bin ldt.o --oformat binary

run: ldt
	qemu-system-i386 ldt.bin


debug: ldt
	qemu-system-i386  ldt.bin -s -S -monitor stdio

clean:  
	-rm *.o *.bin -rf

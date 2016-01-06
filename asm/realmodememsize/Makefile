UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif

CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as
DD=dd

all: memsize


memsize.o: memsize.S
	$(CC) -c  $< 

memsize: memsize.o 
	$(LD)  -Ttext 0x7c00 -o memsize.bin memsize.o --oformat binary

run: memsize
	qemu-system-i386 memsize.bin


debug: memsize
	qemu-system-i386  memsize.bin -s -S -monitor stdio

clean:  
	-rm *.o *.bin -rf

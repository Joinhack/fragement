UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif

CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as
DD=dd

all: rivt


rivt.o: rivt.S
	$(CC) -c  $< 

rivt: rivt.o 
	$(LD)  -Ttext 0x7c00 -o rivt.bin rivt.o --oformat binary

run: rivt
	qemu-system-i386 rivt.bin


debug: rivt
	qemu-system-i386  rivt.bin -s -S -monitor stdio

clean:  
	-rm *.o *.bin -rf

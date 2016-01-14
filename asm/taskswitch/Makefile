UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif

CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as
DD=dd
IMG_NAME=taskswitch.img

all: loader.bin


loader.bin: loader.o taskswitch.o
	$(LD)  -Ttext 0x7c00 -o loader.bin loader.o --oformat binary
	$(LD)  -Ttext 0x0 -o taskswitch.bin taskswitch.o --oformat binary
	cat taskswitch.bin >> loader.bin

%.o: %.S
	$(CC) -c  $< 

run: all
	qemu-system-i386 -fda loader.bin


debug: all
	qemu-system-i386  -fda loader.bin -s -S -monitor stdio

clean:  
	-rm *.o *.bin -rf

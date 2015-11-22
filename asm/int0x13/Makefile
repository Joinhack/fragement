CROSS_COMPILE=/usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
AS=$(CROSS_COMPILE)as
DD=dd

all: int0x13.img

int0x13.o: int0x13.s
	$(AS) -o $@ $<  

int0x13: int0x13.o  
	$(LD) --oformat binary -N -Ttext 0x7c00 -o $@ $< 

int0x13.img: int0x13  
	$(DD) if=int0x13 of=$@ seek=0 count=1
	$(DD) if=/dev/zero of="$@" seek=1 count=2879
	

run:
	qemu-system-i386 -fda int0x13.img

clean:  
	-rm ./int0x13 ./int0x13.img ./floppy.img ./int0x13.o -rf

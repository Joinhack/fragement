CROSS_COMPILE=/usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
AS=$(CROSS_COMPILE)as


all: int0x13.img

int0x13.o: int0x13.s
	$(AS) -o $@ $<  

int0x13: int0x13.o  
	$(LD) --oformat binary -N -Ttext 0x7c00 -o $@ $< 

int0x13.img: int0x13  
	dd if=int0x13 of=int0x13.img bs=512 count=1 

run:
	dd if=Makefile of=floppy.img bs=1  count=512
	qemu-system-i386 -drive file=int0x13.img,index=0,media=disk,format=raw -fda floppy.img

clean:  
	-rm ./int0x13 ./int0x13.img ./floppy.img ./int0x13.o -rf

CROSS_COMPILE=/usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
AS=$(CROSS_COMPILE)as


all: int0x10.img

int0x10.o: int0x10.s  
	$(AS) -o $@ $<  

int0x10: int0x10.o  
	$(LD) --oformat binary -N -Ttext 0x7c00 -o $@ $< 

int0x10.img: int0x10  
	dd if=int0x10 of=int0x10.img bs=512 count=1 

run:
	qemu-system-i386 -drive file=int0x10.img,index=0,media=disk,format=raw

clean:  
	rm ./int0x10 ./int0x10.img ./int0x10.o



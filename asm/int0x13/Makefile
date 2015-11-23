CROSS_COMPILE=/usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
AS=$(CROSS_COMPILE)as
DD=dd
IMG_NAME=int0x13.img

all: $(IMG_NAME)

int0x13.o: int0x13.s
	$(AS) -o $@ $<  

int0x13: int0x13.o  
	$(LD) --oformat binary -N -Ttext 0x7c00 -o $@ $< 

$(IMG_NAME): int0x13  
	$(DD) if=int0x13 of=$@ seek=0 count=1
	$(DD) if=/dev/zero of="$@" seek=1 count=2879

package: $(IMG_NAME)
	mcopy -n -o -i "$(IMG_NAME)" Makefile  ::
	mdir -i "$(IMG_NAME)"

run: package
	qemu-system-i386 -fda int0x13.img


clean:  
	-rm ./int0x13 ./int0x13.img ./floppy.img ./int0x13.o -rf

CROSS_COMPILE=/usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
AS=$(CROSS_COMPILE)as
DD=dd
IMG_NAME=fat12.img

all: $(IMG_NAME)

fat12.o: fat12.s
	$(AS) -o $@ $<  

fat12: fat12.o  
	$(LD) -e _start --oformat binary  -N -Ttext 0x7c00   -o $@ $< 

$(IMG_NAME): fat12  
	$(DD) if=fat12 of=$@ seek=0 count=1
	$(DD) if=/dev/zero of="$@" seek=1 count=2879

package: $(IMG_NAME)
	mcopy -n -o -i "$(IMG_NAME)" Makefile  ::
	mdir -i "$(IMG_NAME)"

run: package
	qemu-system-i386 -fda fat12.img


clean:  
	-rm ./fat12 ./fat12.img ./floppy.img ./fat12.o -rf

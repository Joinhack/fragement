CROSS_COMPILE=/usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
AS=$(CROSS_COMPILE)as
DD=dd
IMG_NAME=fd12.img

all: $(IMG_NAME)

fd12.o: fd12.s
	$(AS) -o $@ $<  

fd12: fd12.o  
	$(LD) --oformat binary -N -Ttext 0x7c00 -o $@ $< 

$(IMG_NAME): fd12  
	$(DD) if=fd12 of=$@ seek=0 count=1
	$(DD) if=/dev/zero of="$@" seek=1 count=2879

package: $(IMG_NAME)
	mcopy -n -o -i "$(IMG_NAME)" Makefile  ::
	mdir -i "$(IMG_NAME)"

run: package
	qemu-system-i386 -fda fd12.img


clean:  
	-rm ./fd12 ./fd12.img ./floppy.img ./fd12.o -rf

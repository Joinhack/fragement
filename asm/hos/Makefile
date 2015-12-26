UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif


CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as

all: raw.img

loader.elf: loader.o
	$(LD) -Ttext 0x7c00 -o $@ $< 

os.elf: os.o
	$(LD) -T os.ld -o $@ $<

raw.img: os.elf loader.elf
	$(OBJCOPY) -I elf32-i386 -O binary loader.elf raw.img
	$(OBJCOPY) -I elf32-i386 -O binary os.elf os.img
	cat os.img >> raw.img

%.o: %.S
	$(CC) -c $<	

run: raw.img
	qemu-system-i386 -fda $<

clean:
	rm -f *.o *.elf *.img

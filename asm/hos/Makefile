UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	CROSS_COMPILE := /usr/local/gcc-4.8.1-for-linux32/bin/i586-pc-linux-
endif


CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)ld
OBJCOPY=$(CROSS_COMPILE)objcopy
AS=$(CROSS_COMPILE)as

all: loader.bin

loader.bin: loader.o os.o
	${LD} -Ttext 0x7C00 -s $< -o $@ --oformat binary
	${LD} -Ttext 0x0 -s os.o -o os.bin --oformat binary
	cat os.bin >> $@

loader.o:
	${CC} -c loader.S

os.o:
	${CC} -c os.S

clean:
	rm -f *.o *.bin

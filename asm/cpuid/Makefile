
%.o:%.s,%.c
	$(CC)  -c -o $@ $^  

cpuid_test:cpuid_test.o cpuid.o
	$(CC)   -o $@ $^  

all:cpuid_test

clean:
	rm *.o

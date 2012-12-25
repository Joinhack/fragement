#include <stdio.h>
#include <stdint.h>

//#undef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8
//#undef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4
#include "atomic.h"

int main(int argc, char const *argv[]) {
	uint64_t i64 = 10, c64;
	uint32_t i32 = 10, c32;
	c64 = atomic_add_uint64(&i64, 20);
	printf("%ld,%ld\n", i64, c64);

	i64 = 20;
	c64 = atomic_sub_uint64(&i64, 5);
	printf("%ld,%ld\n", i64, c64);

	c32 = atomic_add_uint32(&i32, 20);
	printf("%d,%d\n", i32, c32);

	i32 = 20;
	c32 = atomic_sub_uint32(&i32, 5);
	printf("%d,%d\n", i32, c32);

	return 0;
}
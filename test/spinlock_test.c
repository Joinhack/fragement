#include <stdint.h>
#include <stdio.h>
#include <atomic.h>
#include <spinlock.h>

int main(int argc, char const *argv[]) {
	uint64_t p = 100;
	uint32_t p32 = 100;
	spinlock_t lock = SL_UNLOCK;
	int r;
	atomic_add_uint64(&p, 2);
	atomic_sub_uint64(&p, 1);
	r = atomic_cmp_set_uint64(&p, 101, 2);
	printf("%d %lld\n",r, p);

	atomic_add_uint32(&p32, 2);
	atomic_sub_uint32(&p32, 1);
	r = atomic_cmp_set_uint32(&p32, 101, 2);
	printf("%d %ld\n",r, p32);
	spinlock_lock(&lock);
	spinlock_unlock(&lock);
	return 0;
}


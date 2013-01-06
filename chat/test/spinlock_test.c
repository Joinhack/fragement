#include <stdint.h>
#include <stdio.h>
#include <atomic.h>
#include <spinlock.h>
#include <pthread.h>

#define NUMS 30

#ifdef PT_TEST
pthread_spinlock_t lock;
#define LOCK(lock) pthread_spin_lock(lock)
#define UNLOCK(lock) pthread_spin_unlock(lock)
#else
spinlock_t lock = SL_UNLOCK;
#define LOCK(lock) spinlock_lock(lock)
#define UNLOCK(lock) spinlock_unlock(lock)
#endif
long count = 0;


void *spinlock_test(void *d) {
	int i, j;
	for(j = 0; j < 10000; j++) {
		LOCK(&lock);
		for(i = 0; i < 10000; i++)
			count++;
		UNLOCK(&lock);
	}
}

int main(int argc, char const *argv[]) {
	uint64_t p = 100;
	uint32_t p32 = 100;
	
	int r;
	atomic_add_uint64(&p, 2);
	atomic_sub_uint64(&p, 1);
	r = atomic_cmp_set_uint64(&p, 101, 2);
	printf("%d %ld\n",r, p);

	atomic_add_uint32(&p32, 2);
	atomic_sub_uint32(&p32, 1);
	r = atomic_cmp_set_uint32(&p32, 101, 2);
	printf("%d %d\n",r, p32);
	
	size_t i;
	void *code;
	#ifdef PT_TEST
	pthread_spin_init(&lock, 0);
	#endif
	pthread_t threads[NUMS];
	for(i = 0; i < NUMS; i++) {
		pthread_create(&threads[i], NULL, spinlock_test, NULL);	
	}
	for(i = 0; i < NUMS; i++) {
		pthread_join(threads[i], &code);
	}
	printf("%ld\n", count);
	return 0;
}


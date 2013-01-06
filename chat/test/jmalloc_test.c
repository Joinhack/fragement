#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <jmalloc.h>

#ifdef THREAD_TEST
#include <pthread.h>
void *malloc_test(void *p) {
	char *ptr;
	size_t i,times = 50000;
	for(i = 0; i < times; i++) {
		ptr = jmalloc(10);
		printf("%ld\n", get);
		ptr = jrealloc(ptr, 20);
		printf("%ld\n", used_mem());
		jfree(ptr);
		printf("%ld\n", used_mem());
	}
}
#endif

int main(int argc, char const *argv[]) {
	char *ptr = jmalloc(10);
#ifdef THREAD_TEST
#define NUMS 30
	size_t i;
	void *code;
	pthread_t threads[NUMS];
	for(i = 0; i < NUMS; i++) {
		pthread_create(&threads[i], NULL, malloc_test, NULL);	
	}
	for(i = 0; i < NUMS; i++) {
		pthread_join(threads[i], &code);
	}
#endif
	printf("%ld\n", used_mem());
	ptr = jrealloc(ptr, 20);
	printf("%ld\n", used_mem());
	jfree(ptr);
	printf("%ld\n", used_mem());
	return 0;
}

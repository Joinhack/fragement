#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "atomic.h"
#include "jmalloc.h"


#ifdef USE_JEMALLOC
#define malloc(size) je_malloc(size)
#define realloc(ptr, size) je_realloc(ptr, size)
#define free(ptr) je_free(ptr)
#define HAD_MEM_SIZE
#ifdef __APPLE__
#define mem_size(ptr) malloc_size(ptr)
#else
#define mem_size(ptr) malloc_usable_size(ptr)
#endif
#else
#define malloc(size) malloc(size)
#define realloc(ptr, size) realloc(ptr, size)
#define free(ptr) free(ptr)
#endif

#ifndef HAD_MEM_SIZE
#define MEM_PREFIX_SIZE (sizeof(size_t))
#define mem_size(ptr) *((size_t*)ptr - MEM_PREFIX_SIZE)
#endif



#define update_used_mem(size) atomic_add_uint64(&used_mem, size)
#define oom_test(ptr, size) \
if(ptr == NULL) { \
	fprintf(stderr, "Out of memory trying to allocate %ld\n", size); \
	abort(); \
}

uint64_t used_mem = 0;

void *jmalloc(size_t s) {
	void *ptr;
#ifndef HAD_MEM_SIZE
	ptr = malloc(s + MEM_PREFIX_SIZE);
	oom_test(ptr, s);
	*((size_t*)ptr) = s;
	update_used_mem(s + MEM_PREFIX_SIZE);
	return (char*)ptr + MEM_PREFIX_SIZE;
#else
	ptr = malloc(s);
	oom_test(ptr, s);
	update_used_mem(s);
	return ptr;
#endif
}

void *jrealloc(void *ptr, size_t s) {
	void *new_ptr;
	size_t old_size;
#ifndef HAD_MEM_SIZE
	void *real_ptr;
	real_ptr = (char*)ptr - MEM_PREFIX_SIZE;
	old_size = *((size_t*)real_ptr);
	new_ptr = realloc(real_ptr, s);
	oom_test(new_ptr, s);
	*((size_t*)new_ptr) = s;
	update_used_mem(-old_size);
	update_used_mem(s);
	return (char*)new_ptr + MEM_PREFIX_SIZE;
#else
	old_size = mem_size(ptr);
	new_ptr = realloc(ptr, s);
	oom_test(new_ptr, s);
	update_used_mem(-old_size);
	update_used_mem(s);
	return new_ptr;
#endif
}

void jfree(void* ptr) {
	size_t size;
#ifndef HAD_MEM_SIZE
	void *real_ptr;
	real_ptr = (char*)ptr - MEM_PREFIX_SIZE;
	size = *((size_t*)real_ptr);
	update_used_mem(-(size + MEM_PREFIX_SIZE));
	free(real_ptr);
#else
	size = mem_size(ptr);
	update_used_mem(-size);
	free(ptr);
#endif
	
}

int main(int argc, char const *argv[]) {
	char *ptr = jmalloc(10);
	printf("%llu\n", used_mem);
	ptr = jrealloc(ptr, 20);
	printf("%llu\n", used_mem);
	jfree(ptr);
	printf("%llu\n", used_mem);
	return 0;
}



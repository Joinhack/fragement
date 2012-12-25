#include <stdint.h>
#include "atomic.h"
#include "jmalloc.h"

#ifdef USE_JEMALLOC
#define malloc(size) je_malloc(size)
#define realloc(ptr, size) je_realloc(ptr, size)
#define free(ptr) je_free(ptr)
#else
#define malloc(size) malloc(size)
#define realloc(ptr, size) realloc(ptr, size)
#define free(ptr) free(ptr)
#endif

typedef mem_len_t size_t;

#define MEM_PREFIX_SIZE (sizeof(MEM_LEN_TYPE))

#define update_used_mem(size) atomic_add_uint64(&used_mem, size)
#define joom_test(ptr, size) \
if(ptr == null) { \
	fprintf(stderr, "Out of memory trying to allocate %ld\n", size); \
	abort(); \
}

uint64_t used_mem = 0;

void *jmalloc(size_t s) {

	void *ptr = malloc(s + MEM_PREFIX_SIZE);
	*((mem_len_t*)ptr) = s;
	
	joom_test(ptr, s);
	update_used_mem(s);
	return (char*)ptr + MEM_PREFIX_SIZE;
}

void *jrealloc(void *ptr, size_t s) {
	mem_len_t old_size;
	void *real_ptr;
	real_ptr = (char*)ptr + MEM_PREFIX_SIZE;
	old_size = *((mem_len_t*)real_ptr);
	void *p = realloc(real_ptr, s);
	joom_test(p, s);
	*((mem_len_t*)p) = old_size + s;
	update_used_mem(s);
	return p;
}

void jfree(void* ptr) {
	free(ptr);
}



#ifndef ATOMIC_H
#define ATOMIC_H

#include "common.h"


#ifndef CINLINE
uint64_t	atomic_add_uint64(uint64_t *p, uint64_t v);
uint64_t	atomic_sub_uint64(uint64_t *p, uint64_t v);
int atomic_cmp_set_uint64(uint64_t *p, uint64_t o, uint64_t n);

uint32_t	atomic_add_uint32(uint32_t *p, uint32_t v);
uint32_t	atomic_sub_uint32(uint32_t *p, uint32_t v);
int atomic_cmp_set_uint32(uint32_t *p, uint32_t o, uint32_t n);
#endif

#ifdef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8

CINLINE uint64_t	atomic_add_uint64(uint64_t *p, uint64_t v) {
	return __sync_add_and_fetch(p, v);
}

CINLINE uint64_t	atomic_sub_uint64(uint64_t *p, uint64_t v) {
	return __sync_sub_and_fetch(p, v);
}

CINLINE int atomic_cmp_set_uint64(uint64_t *p, uint64_t o, uint64_t n) {
	return __sync_bool_compare_and_swap(p, o, n);
}

#elif (defined(__amd64_) || defined(__x86_64__))

CINLINE uint64_t	atomic_add_uint64(uint64_t *p, uint64_t v) {
	asm volatile (
		"lock; xaddq %0, %1;"
		: "+r" (v), "=m" (*p)
		: "m" (*p)
		);
	return (*p);
}

CINLINE uint64_t	atomic_sub_uint64(uint64_t *p, uint64_t v) {
	v = -v;
	asm volatile (
		"lock; xaddq %0, %1;"
		: "+r" (v), "=m" (*p)
		: "m" (*p)
		);
	return (*p);
}

CINLINE int atomic_cmp_set_uint64(uint64_t *p, uint64_t o, uint64_t n) {
	char result;
	asm volatile (
		"lock; cmpxchgq %3, %0; setz %1;"
		: "=m"(*p), "=q" (result) 
		: "m" (*p), "r" (n), "a" (o) : "memory"
		);
	return (result);
}

#else
#  error "not support atomic"
#endif  //end define the 64 bit



#ifdef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4

CINLINE uint32_t	atomic_add_uint32(uint32_t *p, uint32_t v) {
	return __sync_add_and_fetch(p, v);
}

CINLINE uint32_t	atomic_sub_uint32(uint32_t *p, uint32_t v) {
	return __sync_sub_and_fetch(p, v);
}

CINLINE int atomic_cmp_set_uint32(uint32_t *p, uint32_t o, uint32_t n) {
	return __sync_bool_compare_and_swap(p, o, n);
}

#elif (defined(__i386__) || defined(__amd64__) || defined(__x86_64__))

CINLINE uint32_t	atomic_add_uint32(uint32_t *p, uint32_t v) {
	asm volatile (
		"lock; xaddl %0, %1;"
		: "+r" (v), "=m" (*p)
		: "m" (*p)
		);
	return (*p);
}

CINLINE uint32_t	atomic_sub_uint32(uint32_t *p, uint32_t v) {
	v = -v;
	asm volatile (
		"lock; xaddl %0, %1;"
		: "+r" (v), "=m" (*p)
		: "m" (*p)
		);
	return (*p);
}

CINLINE int atomic_cmp_set_uint32(uint32_t *p, uint32_t o, uint32_t n) {
	char result;
	asm volatile (
		"lock; cmpxchgl %3, %0; setz %1;"
		: "=m"(*p), "=q" (result) 
		: "m" (*p), "r" (n), "a" (o) : "memory"
		);
	return (result);
}


#else
#  error "not support atomic"
#endif

#endif /*ATOMIC head define**/

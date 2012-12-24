#ifndef ATOMIC_H
#define ATOMIC_H

#ifndef _INLINE
#define _INLINE __inline__

uint64_t	atomic_add_uint64(uint64_t *p, uint64_t v);
uint64_t	atomic_sub_uint64(uint64_t *p, uint64_t v);

uint64_t	atomic_add_uint32(uint64_t *p, uint32_t v);
uint64_t	atomic_sub_uint32(uint64_t *p, uint32_t v);

#ifdef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8
_INLINE uint64_t	atomic_add_uint64(uint64_t *p, uint64_t v) {
	return __sync_add_and_fetch(p, v);
}

_INLINE uint64_t	atomic_sub_uint64(uint64_t *p, uint64_t v) {
	return __sync_sub_and_fetch(p, v);
}
#elif (defined(__amd64_) || defined(__x86_64__))
_INLINE uint64_t	atomic_add_uint64(uint64_t *p, uint64_t v) {
	asm volatile (
		"lock; xaddq %0, %1;"
		: "+r" (v), "=m" (*p)
		: "m" (*p)
		);
	return (v);
}
_INLINE uint64_t	atomic_sub_uint64(uint64_t *p, uint64_t v) {
	v = -v;
	asm volatile (
		"lock; xaddq %0, %1;"
		: "+r" (v), "=m" (*p)
		: "m" (*p)
		);
	return (v);
}
#endif


#endif /*ATOMIC head define**/

#ifndef ATOMIC_H
#define ATOMIC_H

#ifndef _INLINE
#define _INLINE __inline__

uint64_t	atomic_add_uint64(uint64_t *p, uint64_t x);
uint64_t	atomic_sub_uint64(uint64_t *p, uint64_t x);

uint64_t	atomic_add_uint32(uint64_t *p, uint32_t x);
uint64_t	atomic_sub_uint32(uint64_t *p, uint32_t x);




#endif /*ATOMIC head define**/

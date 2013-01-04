#ifndef SPINLOCK_H
#define SPINLOCK_H

#define SL_UNLOCK 0
#define SL_LOCKED 1

#ifndef CINLINE
#define CINLINE static inline
#endif
#include "atomic.h"

typedef uint32_t spinlock_t;

#ifndef CINLINE
int spinlock_trylock(spinlock_t *lock);
void spinlock_unlock(spinlock_t *lock);
#endif

int spinlock_lock(spinlock_t *lock);


CINLINE int spinlock_trylock(spinlock_t *lock) {
	return *lock == SL_UNLOCK && atomic_cmp_set_uint32(lock, SL_UNLOCK, SL_LOCKED);
}

CINLINE void spinlock_unlock(spinlock_t *lock) {
	*lock = SL_UNLOCK;
}

#endif /*end define spinlock**/

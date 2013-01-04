#include <stdio.h>
#include <stdint.h>
#include "spinlock.h"
#include "cprocess.h"

/*
 *if acquire lock return 1 else return 0
 */
int spinlock_lock(spinlock_t *lock) {
	while(1) {
		
		if(*lock == SL_UNLOCK && atomic_cmp_set_uint32(lock, SL_UNLOCK, SL_LOCKED))
			return 1;
		CSCHED_YIELD();
	}
}


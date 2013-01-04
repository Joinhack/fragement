#include <stdio.h>
#include <stdint.h>
#include "spinlock.h"
#include "cprocess.h"

/*
 *if acquire lock return 1 else return 0
 */
void spinlock_lock(spinlock_t *lock) {
	int i, n;
	while(1) {
		if(*lock == SL_UNLOCK && atomic_cmp_set_uint32(lock, SL_UNLOCK, SL_LOCKED)) {
			return;
		}
		if(CPU_NUM > 1) {
			for(i = 0; i < CPU_NUM; i++) {
				for(n = 1; n < CPU_NUM; n++)
					CPU_PAUSE();
				if(*lock == SL_UNLOCK && atomic_cmp_set_uint32(lock, SL_UNLOCK, SL_LOCKED)) {
					return;
				}
			}
		}
		CSCHED_YIELD();
	}
}


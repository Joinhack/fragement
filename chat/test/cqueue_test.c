#include <stdio.h>
#include <stdint.h>
#include <cqueue.h>
#include <pthread.h>
#include <spinlock.h>

#define NUMS 10

uint32_t count;

cqueue *cq;
spinlock_t lock;

void *cqueue_pop_mt(void *data) {
	size_t i = 0;
	for(i = 0; i < 100000; i++) {
		spinlock_lock(&lock);
		cqueue_push(cq, NULL);
		spinlock_unlock(&lock);
	}
	spinlock_lock(&lock);
	while(cqueue_len(cq) > 0) {
		count++;
		fprintf(stdout, "%ld pop\n", pthread_self());
		cqueue_pop(cq);
	}
	spinlock_unlock(&lock);
	return NULL;
}

int main(int argc, char const *argv[]) {
	size_t i;
	lock = SL_UNLOCK;
	cq = create_cqueue();
	count = 0;
	cqueue_item *cqi;
	for(i = 0; i < 6; i++)
		cqueue_push(cq, NULL);
	cqi = cq->head;

	cqueue_pop(cq);
	cqueue_pop(cq);
	cqueue_pop(cq);
	cqueue_pop(cq);
	cqueue_pop(cq);
	cqueue_pop(cq);
	for(i = 0; i < 1; i++) {
		printf("%llu, %llu, %llu\n", (void*)cqi, (void*)cqi->next, (void*)cqi->prev);
		cqi = cqi->next;
	}
	cqueue_pop(cq);
	printf("%ld\n", cqueue_len(cq));
	pthread_t threads[NUMS];
	void *code;
	fprintf(stderr, "push finish\n");
	for(i = 0; i < NUMS; i++) {
		pthread_create(&threads[i], NULL, cqueue_pop_mt, NULL);	
	}
	for(i = 0; i < NUMS; i++) {
		pthread_join(threads[i], &code);
	}
	destory_cqueue(cq);
	printf("%ld\n", cqueue_len(cq));
	printf("%lu\n", count);
	return 0;
}


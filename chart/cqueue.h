#ifndef CQUEUE_H
#define CQUEUE_H

#ifndef INLINE
#define INLINE inline //USE C99 keyword.
#endif

typedef struct _cqueue_item {
	struct _cqueue_item *prev;
	struct _cqueue_item *next;
	void *data;
} cqueue_item;

typedef struct {
	cqueue_item *head;
	size_t count;
} cqueue;

cqueue *create_cqueue();
void destory_cqueue(cqueue *cq);
void *cqueue_pop(cqueue *cq);
void cqueue_push(cqueue *cq, void *data);

INLINE size_t cqueue_len(cqueue *cq) {
	return cq->count;
}

#endif /* end define common queue **/

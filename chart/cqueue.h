#ifndef CQUEUE_H
#define CQUEUE_H

typedef struct cqueue_item;

typedef struct {
	cqueue *prev;
	cqueue *next;
	void *data;
} cqueue_item;

typedef struct {
	cqueue_item *head;
	size_t count;
} cqueue;

cqueue *create_cqueue();
void destory_cqueue(cqueue *cq);
void *cqueue_pop(cqueue *cq);
int cqueue_push(cqueue *cq, void *data);
size_t cqueue_len(cqueue *cq);

#endif /* end define common queue **/

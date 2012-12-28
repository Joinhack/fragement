#include <stdio.h>
#include <string.h>
#include "jmalloc.h"

static cqueue_item *create_cqueue_item() {
	cqueue_item *cq_item;
	size_t len = sizeof(cqueue_item);
	cq_item = jmalloc(len);
	cq_item->next = NULL;
	cq_item->prev = NULL;
	cq_item->data = NULL;
	return cq_item;
}

static void destory_cqueue_item(cqueue_item *item) {
	jfree(item);
}

cqueue *create_cqueue() {
	cqueue *cq;
	size_t len = sizeof(cqueue);
	cq = jmalloc(len);
	cq->head = NULL;
	cq->count = 0;
	return cq
}

void *cqueue_pop(cqueue *cq) {
	void *data;
	cqueue_item *item;
	if(cq->count == 0)
		return NULL;
	item = cq->head->prev;
	data = item->data;
	item->prev->next = item->next;
	item->next->prev = item->prev;
	cq->count--;
	destory_cqueue_item(item);
}

void cqueue_push(cqueue *cq, void *data) {
	cqueue_item *item;
	item = create_cqueue_item();
	item->data = data;
	item->next = cq->head;
	if(head != NULL)
		item->prev = cq->head->prev;
	else
		item->prev = item;
	cq->head = item;
	cq->count++;
}


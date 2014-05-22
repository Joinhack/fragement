#ifndef SKIPLIST_H
#define SKIPLIST_H

#define MAX_HEIGHT 5

typedef struct node {
	int key;
	struct node *next[1];
} node;

typedef struct skiplist {
	int height;
	node *head;
} skiplist;


skiplist* skiplist_new();
void skiplist_free(skiplist*);

#endif

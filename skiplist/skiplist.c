#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "skiplist.h"

static node* node_new(int k,int h) {
	size_t s = sizeof(node) + (sizeof(node*)*(h - 1));
	node *n = malloc(s);
	memset((void*)n, 0, s);
	n->key = k;
	return n;
}

static void node_free(node *n) {
	free(n);
}


skiplist* skiplist_new() {
	skiplist *sl = malloc(sizeof(skiplist));
	sl->head = node_new(INT_MIN, MAX_HEIGHT);
	sl->height = 1;
	return sl;
}

node* skiplist_find_prev(skiplist *sl, int k, node* prev[]) {
	int l = sl->height - 1;
	node *n;
	n = sl->head;
	while(1) {
		node *next = n->next[l];
		if (next != NULL && k < next->key) {
			n = next;
		} else {
			if (prev) prev[l] = n;
			if (l == 0)
				return n;
			l--;
		}
	}
	return NULL;
}

node* skiplist_find_prev_or_eq(skiplist *sl, int k, node* prev[]) {
	int l = sl->height - 1;
	node *n;
	n = sl->head;
	while(1) {
		node *next = n->next[l];
		if (next != NULL && k <= next->key) {
			n = next;
		} else {
			if (prev) prev[l] = n;
			if (l == 0)
				return n;
			l--;
		}
	}
	return NULL;
}

int skiplist_remove(skiplist *sl, int k) {
	int l;
	node *prev[MAX_HEIGHT];
	node *n = skiplist_find_prev(sl, k, prev);
	if (n == NULL || n->next[0] == NULL)
		return 1;
	if (n->next[0]->key != k)
		return 0;
	n = n->next[0];
	for (int i = 0; i < sl->height; i++) {
		if (prev[i]->next[i] != NULL && prev[i]->next[i]->key == k)
			prev[i]->next[i] = n->next[i];
	}
	for (l = sl->height; l > 0; l--) {
		if(sl->head->next[l-1] != NULL)
			break;
	}
	sl->height = l== 0?1:l;
	node_free(n->next[0]);
	return 0;
}

int skiplist_contains(skiplist *sl, int k) {
	node *n = skiplist_find_prev_or_eq(sl, k, NULL);
	if(n != NULL && n->key == k)
		return 1;
	else
		return 0;
}


static int skiplist_random(skiplist *sl) {
	static const unsigned int kBranching = 4;
  int height = 1;
  while (height < MAX_HEIGHT && ((random() % kBranching) == 0)) {
    height++;
  }
  return height;
}

int skiplist_insert(skiplist *sl, int k) {
	node *prev[MAX_HEIGHT];
	node *n, *next;
	int randomHeight, l;
	if (sl == NULL)
		return -1;

	n = skiplist_find_prev_or_eq(sl, k, prev);
	if (n != NULL && n->key == k) {
		return 1;
	}
	randomHeight = skiplist_random(sl);
	if(randomHeight > sl->height) {
		for(int i = sl->height; i < randomHeight ; i++) {
			prev[i] = sl->head;
		}
		sl->height = randomHeight;
	}
	n = node_new(k, randomHeight);
	for(l = 0; l < randomHeight; l++) {
		 n->next[l] = prev[l]->next[l];
		 prev[l]->next[l] = n;
	}
	return 0;
}

void skiplist_dump(skiplist *sl) {
	node *n;
	for(int i = sl->height - 1; i  >=0; i--) {
		printf("level %d:", i);
		n = sl->head->next[i];
		while(n != NULL) {
			printf(" %d", n->key);
			n = n->next[i];
		}
		printf("\n");
	}
}


int main() {
	static const int limit = 100;
	skiplist *sl = skiplist_new();
	for (int i = 0; i < limit; i++) {
		skiplist_insert(sl, i);
		
	}
	skiplist_dump(sl);
	skiplist_remove(sl, 71);
	skiplist_dump(sl);
	for (int i = 0; i < limit; i++) {
		skiplist_remove(sl, i);
	}
	skiplist_dump(sl);
	return 0;
}


#ifndef _BTREE_
#define _BTREE_

typedef struct _bnode {
	int *vals;
	int leaf;
	int size;	// val array size.
	struct _bnode *children;	//the children array size should be size + 1
} bnode;

typedef struct _btree {
	bnode *root;
	size_t arraySize;
} btree;

bnode* btreeSearch(btree *tree, int val);

bnode* btreeInsert(btree *tree, int val);

#endif

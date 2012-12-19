#ifndef _BTREE_
#define _BTREE_

typedef struct _bnode {
	int *val;
	int size;	// val array size.
	struct _bnode *children;	//the children array size should be size + 1
} bnode;

typedef struct _btree {
	
} btree;

#endif

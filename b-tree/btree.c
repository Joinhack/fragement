#include <stdio.h>


bnode* bnodeInsertNonfull(bnode *node, int val);

bnode bnodeSearch(bnode *node, int val);

static bnode bnodeSearch(bnode *node, int val) {
	bnode *current = node;
	size_t max, min, i;
	while(current) {
		i = 0;
		while(i < current->size && val > current->vals[i]) {
			i++;
		}
		if(val == current->vals[i]) {
			return current;
		}
		if(current->leaf)
			return NULL;
		current = current->children[i];
	}
}

bnode* btreeSearch(btree *tree, int val) {
	return bnodeSearch(tree->root, val);
}

static bnode* bnodeInsertNonfull(bnode *node, int val) {
	int i = node->size - 1;
	if(node.leaf) {
		while(i >= 0 && val < node->vals[i]) {
			node->vals[i+1] = node->vals[i];
			i--;
		}
		node->vals[i] = val;
		node->size++;
	}
}

bnode* btreeInsert(btree *tree, int val) {
	bnode *node = tree->node;
	if(node->size == tree.arraySize) {

	} else {
		bnodeInsertNonfull(node, val);
	}
}

int main(int argc, char *argv[]) {
	return 0;
}

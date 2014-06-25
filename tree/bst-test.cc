#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <limits.h>
#include <time.h>
#include "bst.h"
#include "avltree.h"

template<typename T>
class Comparator {
public:
	int operator()(const T &t1, const T &t2) {
		return (int)(t1 - t2);
	}
};

template<typename BST>
void DumpPrint(const typename BST::Node *n) {
	std::cout << n->key << " ";
}

long prev = ULONG_MAX;

template<typename BST>
void Bigger(const typename BST::Node *n) {
	assert(prev < (long)n->key);
	prev = n->key;
}

int count;
template<typename BST>
void Count(const typename BST::Node *n) {
	count++;
}

template<typename BST>
void Test(BST bst) {
	size_t len = 10;
	int k[len];
	srandom(time(NULL));
	for(int i = 0; i < len; i++) {
		
		while(true) {
			L1:
			int v = (int)random();
			for(int m; m < i; m++) {
				if(v == k[m])
					goto L1;
			}
			k[i] = v;
			break;
		}
		bst.Insert(k[i]);
		count = 0;
		bst.Walk(Count<BST>);

	}

	//verify.
	for(int i = 0; i < len; i++) {
		assert(k[i] == bst.Search(k[i])->key);
	}
	for(int i = 0; i < len; i++) {
		bst.Walk(Bigger<BST>);
		prev = ULONG_MAX;
	}
	for(int i = 0; i < len; i++) {
		assert(bst.Delete(k[i]));
		bst.Walk(Bigger<BST>);
		prev = ULONG_MAX;
	}
}

int main() {
	BSTree<int, Comparator<int> > bst = BSTree<int, Comparator<int> >();
	std::cout << "binary search tree testing." << std::endl;
	Test(bst);
	AVLTree<int, Comparator<int> > avl = AVLTree<int, Comparator<int> >();
	std::cout << "AVL tree testing." << std::endl;
	Test(avl);
	
	return 0;
}
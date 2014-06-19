#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <limits.h>
#include <time.h>
#include "bst.h"


template<typename T>
class Comparator {
public:
	int operator()(const T &t1, const T &t2) {
		return (int)(t1 - t2);
	}
};

void DumpPrint(const BSTree<int, Comparator<int> >::Node *n) {
	std::cout << n->key << " ";
}

long prev = ULONG_MAX;

void Bigger(const BSTree<int, Comparator<int> >::Node *n) {
	assert(prev < (long)n->key);
	prev = n->key;
}

int main() {
	BSTree<int, Comparator<int> > bst = BSTree<int, Comparator<int> >();
	size_t len = 100;
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
		bst.Insert(k[i], NULL);
	}
	for(int i = 0; i < len; i++) {
		assert(k[i] == bst.Search(k[i])->key);
	}
	bst.Walk(DumpPrint);
	std::cout << std::endl;
	for(int i = 0; i < len; i++) {
		assert(bst.Delete(k[i]));
		bst.Walk(Bigger);
		prev = ULONG_MAX;
	}

	return 0;
}
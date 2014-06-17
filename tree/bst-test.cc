#include <iostream>
#include "bst.h"

template<typename T>
class Comparator {
public:
	int operator()(const T &t1, const T &t2) {
		return (int)(t1 - t2);
	}
};

void DumpPrint(const BSTree<int, Comparator<int> >::Node *n) {
	std::cout << n->key << std::endl;
}

int main() {
	BSTree<int, Comparator<int> > bst = BSTree<int, Comparator<int> >();
	for(int i = 100; i >- 0; i--) {
		bst.Insert(i, NULL);
	}
	bst.Walk(DumpPrint);
	return 0;
}
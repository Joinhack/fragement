#ifndef AVL_TREE
#define AVL_TREE

template<typename Key, typename Comaparator>
class AVLTree {
public:
	struct Node;

	AVLTree():root_(NULL) {}

	Node* Insert(const Key&);

	Node* Search(const Key&);

	bool Delete(const Key&);

protected:
	Node* NewNode(const Key&);

	Node* Find(const Key&);

private:
	Comparator cmp_;
	Node *root_;
};

/**
factor: the height differences of value for left right(fuck english)
				结点的左、右子树的高度差

example.

        0                
       / \            
      1  -1           
     /     \            
    0       0            

        1                
       / \            
      1	 -1           
     /     \            
    -1      0            
     \            
      0

follow need balance.

        1                
       / \            
      2  -1           
     /     \            
    -1      0            
     \            
      -1     

*/
template<typename Key, typename Comaparator>
struct AVLTree<Key, Comaparator>::Node {
	Key key;
	Node *left_;
	Node *right_;
	int factor; //the blance factor: the left height
	Node(Key& k):key(k), left_(NULL), right_(NULL) {}
};

template<typename Key, typename Comaparator>
inline typename AVLTree<Key, Comaparator>::Node*  AVLTree<Key, Comaparator>::NewNode(const Key& k) {
	return new Node(k);
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node*  AVLTree<Key, Comaparator>::Find(const Key& key) {
	Node *n = root_;
	while(n) {
		int rs = cmp_(key, n->key);
		if(!rs) break;
		if(rs < 0) 
			n = n->left_;
		else 
			n = n->right_;
	}
	return n;
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node*  AVLTree<Key, Comaparator>::Insert(const Key &key) {
	Find(key)
}

#endif //end define

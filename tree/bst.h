#ifndef BST_TREE
#define BST_TREE

#include <vector>

template<typename Key, typename Comparator>
class BSTree {
public:
	struct Node;
	Node* NewNode(const Key&, void*);
	Node* Search(const Key&);
	Node* Insert(const Key&, void*);
	bool Delete(const Key&);
	template<typename T>
	void Walk(const T &);
	virtual ~BSTree() {
		Walk(Free);
	}
protected:
	static void Free(const Node* n) {delete  n;}
	Node* Find(const Key &);
private:
	Node* root_;
	Comparator cmp_;
};

template<typename Key, typename Comparator>
struct BSTree<Key, Comparator>::Node {
	Key key;
	void* value;
	Node(const Key &k, void* v):key(k), value(v), left_(NULL), right_(NULL) {}
	Node *left_;
	Node *right_;
};

template<typename Key, typename Comparator>
typename BSTree<Key, Comparator>::Node* BSTree<Key, Comparator>::Search(const Key &key) {
	Node *n = Find(key);
	if(n && cmp_(n->key, key) == 0)
		return n;
	return NULL;
}


template<typename Key, typename Comparator>
typename BSTree<Key, Comparator>::Node* BSTree<Key, Comparator>::Find(const Key &key) {
	Node *n = root_;
	while(n) {
		int rs = cmp_(key, n->key);
		if(rs == 0) return n;
		if(rs > 0) {
			if (n->right_)
				n = n->right_;
			else
				break;
		}
		else {
			if (n->left_)
				n = n->left_;
			else
				break;
		}
	}
	return n;
}

template<typename Key, typename Comparator>
typename BSTree<Key, Comparator>::Node* BSTree<Key, Comparator>::NewNode(const Key &key, void *val) {
	return new Node(key, val);
}

template<typename Key, typename Comparator>
template<typename T>
inline void BSTree<Key, Comparator>::Walk(const T &caller) {
	Node *node;
	std::vector<Node*> nodes;
	if(root_ != NULL)
		nodes.push_back(root_);
	while((node = nodes.back())) {
		nodes.pop_back();
		if (node->left_) nodes.push_back(node->left_);
		if (node->right_) nodes.push_back(node->right_);
		caller(node);
	}
}

template<typename Key, typename Comparator>
bool BSTree<Key, Comparator>::Delete(const Key &key) {
	
}

template<typename Key, typename Comparator>
typename BSTree<Key, Comparator>::Node* BSTree<Key, Comparator>::Insert(const Key &key, void *val) {
	int rs;
	Node *n = Find(key);
	Node *nNode;
	if(n) {
		rs = cmp_(key, n->key);
		//if node exist, just modify the value.
		if(!rs) {
			n->value = val;
			return n;
		}
		nNode = NewNode(key, val);
		if(rs < 0)
			n->left_ = nNode;
		else
			n->right_ = nNode;
	} else {
		nNode = NewNode(key, val);
		root_ = nNode;
	}
	return nNode;
}

#endif

#ifndef BST_TREE
#define BST_TREE

#include <vector>

template<typename Key, typename Comparator>
class BSTree {
public:
	BSTree():root_(NULL) {}
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
	static void Free(Node* n) {delete  n;}
	Node* Find(const Key&);
	void Link(Node *n, Node *n2);
private:
	Node* root_;
	Comparator cmp_;
};

template<typename Key, typename Comparator>
struct BSTree<Key, Comparator>::Node {
	Key key;
	void* value;
	Node(const Key &k, void* v):key(k), value(v), left_(NULL), right_(NULL), parent_(NULL) {}
	Node *parent_;
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
inline void BSTree<Key, Comparator>::Link(Node *n, Node *n2) {
	if(n->parent_ == NULL) 
		root_ = n2;
	else if(n->parent_->left_ == n)
		n->parent_->left_ = n2;
	else {
		n->parent_->right_ = n2;
	}
	if(n2) 
		n2->parent_ = n->parent_;
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
	while(!nodes.empty()) {
		node = nodes.back();
		nodes.pop_back();
		if (node->left_) nodes.push_back(node->left_);
		if (node->right_) nodes.push_back(node->right_);
		caller(node);
	}
}

template<typename Key, typename Comparator>
bool BSTree<Key, Comparator>::Delete(const Key &key) {
	Node *n = Find(key);
	//no node found.
	if (n == NULL || cmp_(key, n->key) != 0)
		return false;

	//root
	if (!n->left_) {
		Link(n, n->right_);
	} else if (!n->right_) {
		Link(n, n->left_);
	} else {
		Node *rmin = n->right_;
		while(rmin) {
			if(!rmin->left_)
				break;
			rmin = rmin->left_;
		}
		if(rmin->parent_ != n) {
			Link(rmin, rmin->right_);
			rmin->right_ = n->right_;
			rmin->right_->parent_ = rmin;
		}
		Link(n, rmin);
		rmin->left_ = n->left_;
		rmin->left_->parent_ = rmin;
	}
	
	delete n;
	return true;
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
		nNode->parent_ = n;
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

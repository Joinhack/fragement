#ifndef AVL_TREE
#define AVL_TREE

#include <vector>
#include <cctype>

template<typename Key, typename Comparator>
class AVLTree {
public:
	struct Node;

	AVLTree():root_(NULL) {}

	Node* Insert(const Key&);

	Node* Search(const Key&);

	bool Delete(const Key&);

	template<typename T>
	void Walk(const T &);

protected:
	Node* NewNode(const Key&);

	Node* Find(const Key&, std::vector<Node*>&);

	bool Rotate(std::vector<Node*>&, int idx);

	Node* LL(Node *n);

	Node* LR(Node *n);

	Node* RL(Node *n);

	Node* RR(Node *n);

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
	Node(const Key& k):key(k), left_(NULL), right_(NULL), factor(0) {}
};

//In-Order traversal
template<typename Key, typename Comparator>
template<typename T>
void AVLTree<Key, Comparator>::Walk(const T &caller) {
	Node* node;
	std::vector<Node*> nodes;
	node = root_;
	while(node || !nodes.empty()) {
		while(node) {
			nodes.push_back(node);
			node = node->left_;
		}
		if(!nodes.empty()) {
			node = nodes.back();
			nodes.pop_back();
			//maybe free the node in caller. so get right node before call caller
			Node *rnode = node->right_;
			caller(node);
			node = rnode;
		}
	}
}

template<typename Key, typename Comaparator>
inline typename AVLTree<Key, Comaparator>::Node*  AVLTree<Key, Comaparator>::NewNode(const Key& k) {
	return new Node(k);
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node*  AVLTree<Key, Comaparator>::Search(const Key& k) {
	std::vector<Node*> path;
	Node *n = Find(k, path);
	if(n && cmp_(k, n->key) == 0) return n;
	return NULL;
}

template<typename Key, typename Comaparator>
bool  AVLTree<Key, Comaparator>::Delete(const Key& k) {
	std::vector<Node*> path;
	//not implement pretty,  so mock
	if(true) return true;
	Node *n = Find(k, path);
	if(!n) return false;
	if(cmp_(k, n->key) != 0) return false;
	if(n->left_ && n->right_) {
		Node *tmp = n->left_;
		path.push_back(tmp);
		while(tmp->right_) {
			tmp = tmp->right_;
			path.push_back(tmp);
		}
		size_t idx = path.size() - 1;
		n->key = tmp->key;
		if(path[idx - 1] == n) {
			path[idx - 1]->left_ = tmp->left_;
		} else {
			path[idx - 1]->right_ = tmp->left_;
		}
	} else {
		Node *ntmp = n->left_;
		if(!ntmp) {
			ntmp = n->right_;
		}
		int idx = path.size() - 1;
		if(idx > 0) {
			if(path[idx - 1]->left_ == n) {
				path[idx - 1]->left_ = ntmp;
			} else {
				path[idx - 1]->right_ = ntmp;
			}
		} else {
			root_ = ntmp;
		}
	}
	
	for(int idx = path.size() - 2; idx > 0; idx--) {
		Node *node = path[idx];
		int factor = cmp_(k, node->key) <= 0 ? -1 : 1;
		node->factor += factor;
		if(node->factor != 0) {
			if(node->factor == 1 || node->factor == -1 || !Rotate(path, idx))
				break;
		}		
	}
	delete n;
	return true;
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node*  AVLTree<Key, Comaparator>::Find(const Key& key, std::vector<Node*> &p) {
	Node *n = root_;
	while(n) {
		int rs = cmp_(key, n->key);
		p.push_back(n);
		if(!rs) break;
		if(rs < 0) {
			if(n->left_) 
				n = n->left_;
			else
				break;
		}
		else {
			if(n->right_) 
				n = n->right_;
			else
				break;
		}
	}
	return n;
}


/*

when the factor of root for rotation  is 2
  if the left factor is 1, this is LL type. use LL rotation.
  if the left factor is -1, this is LR type. use LR rotation.

when the factor of root for rotation is -2
  if the left factor is 1, this is RL type. use RL rotation.
  if the left factor is -1, this is RR type. use RR rotation.
*/
template<typename Key, typename Comaparator>
bool AVLTree<Key, Comaparator>::Rotate(std::vector<Node*>& path, int idx) {
	Node* n = path[idx];
	Node* nroot = NULL;
	bool isHeightChanged = true;
	if(n->factor == 2) {
		if(n->left_->factor == 1) {
			nroot = LL(n);
		} else if(n->left_->factor == -1) {
			nroot = LR(n);
		} else { //only delete will call this
			nroot = LL(n);
			isHeightChanged = false;
		}
	}
	if(n->factor == -2) {
		if(n->right_->factor == 1) {
			nroot = RL(n);
		} else if(n->right_->factor == -1) {
			nroot = RR(n);
		} else { //only delete will call this
			nroot = RR(n);
			isHeightChanged = false;
		}
	}
	if(idx > 0) {
		Node* p = path[idx - 1];
		if(cmp_(nroot->key, p->key) < 0) {
			p->left_ = nroot;
		} else {
			p->right_ = nroot;
		}
	} else {
		root_ = nroot;
	}
	return isHeightChanged;
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node* AVLTree<Key, Comaparator>::LL(Node *n) {
	Node *nl = n->left_;
	n->left_ = nl->right_;
	nl->right_ = n;
	if(nl->factor == 1) {
		nl->factor = 0;
		n->factor = 0;
	} else { //when delete
		nl->factor = -1;
		n->factor = 1;
	}
	return nl;
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node* AVLTree<Key, Comaparator>::LR(Node *n) {
	Node *nl = n->left_;
	Node *nlr = nl->right_;
	n->left_ = nlr->right_;
	nl->right_ = nlr->left_;
	nlr->left_ = nl;
	nlr->right_ = n;
	if(nlr->factor == 0) {
		nl->factor = 0;
		n->factor = 0;
	} else if (nlr->factor == 1) {
		n->factor = -1;
		nl->factor = 0;
	} else if (nlr->factor == -1) {
		n->factor = 0;
		nl->factor = 1;
	}
	nlr->factor = 0;
	return nlr;
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node* AVLTree<Key, Comaparator>::RR(Node *n) {
	Node *nr = n->right_;
	n->right_ = nr->left_;
	nr->left_ = n;
	if(nr->factor == -1) {
		nr->factor = 0;
		n->factor = 0;
	}  else { //when delete
		nr->factor = 1;
		n->factor = -1;
	}
	return nr;
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node* AVLTree<Key, Comaparator>::RL(Node *n) {
	Node *nr = n->right_;
	Node *nrl = nr->left_;
	n->right_ = nrl->left_;
	nr->left_ = nrl->right_;
	nrl->right_ = nr;
	nrl->left_ = n;
	if(nrl->factor == 0) {
		nr->factor = 0;
		n->factor = 0;
	} else if (nrl->factor == 1) {
		n->factor = 0;
		nr->factor = -1;
	} else if (nrl->factor == -1) {
		n->factor = 1;
		nr->factor = 0;
	}
	nrl->factor = 0;
	return nrl;
}

template<typename Key, typename Comaparator>
typename AVLTree<Key, Comaparator>::Node*  AVLTree<Key, Comaparator>::Insert(const Key &key) {
	std::vector<Node*> path;
	Node *nNode = NULL;
	int idx;
	Node *n = Find(key, path);
	if(n) {
		int rs = cmp_(key, n->key);
		if(!rs) return n;
		nNode = NewNode(key);
		if(rs < 0)
			n->left_ = nNode;
		else
			n->right_ = nNode;
		for(idx = path.size() - 2; idx >= 0; idx--) {
			n = path[idx];
			//The parent node increment for factor. if left +1 if right -1.
			int increment = cmp_(key, n->key) < 0? 1: -1;
			n->factor += increment;
			// if the factor is 0, already balanced.
			if(n->factor == 0) break;
			if(n->factor == 2 || n->factor == -2) {
				Rotate(path, idx);
				break;
			}
		}
	} else {
		nNode = NewNode(key);
		root_ =  nNode;
	}
	return nNode;
}

#endif //end define

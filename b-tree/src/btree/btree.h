#ifndef BTREE_H
#define BTREE_H
#include "persist/layout.h"
#include "node.h"
#include "sys/atomic.h"

namespace ndb {

class BTree {
public:

  BTree(Layout &layout, Comparator *comparator);

  Node* createNode(bid_t bid) {
    if(bid >= NID_LEAF_START)
      return (Node*)new InnerNode(this, bid);
    if(bid < NID_LEAF_START && bid > NID_START) {
      return (Node*)new LeafNode(this, bid);
    }
    // can't be here
    assert(false);
    return NULL;
  }

  Node* nextInnerNode() {
    bid_t nbid = atomic_add_uint64(&_innerNodeBID, 1);
    return createNode(nbid);
  }

  Node* nextLeafNode() {
    bid_t nbid = atomic_add_uint64(&_leafnodeBID, 1);
    return createNode(nbid);
  }

  bool put(Buffer key, Buffer value) {
    Msg msg(key.clone(), value.clone());
    msg.setType(PUT);
    return _root->writeMsg(msg);
  }

  bool init();

private:

  friend class InnerNode; 
  friend class LeafNode;

  Layout& _layout;

  Comparator *_comparator;

  InnerNode *_root;

  //current inner node bid
  bid_t _innerNodeBID;

  //current leaf node bid
  bid_t _leafnodeBID;
};

};

#endif

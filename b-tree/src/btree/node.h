#ifndef NODE_H
#define NODE_H
#include "persist/block.h"

#define NID_NONE            0
#define NID_START           (NID_NIL + 2)
#define NID_LEAF_START      (bid_t)((1LL << 48) + 1)
#define IS_LEAF(nid)        ((nid) >= NID_LEAF_START)

namespace ndb {

class BTree;

class Node {
public:

  virtual ~Node() = 0;

  void setDirty(bool b) {
    _dirty = b;
  }

  bool dirty() {
    return _dirty;
  }

  bid_t nid() {
    return _nid;
  }

protected:
  virtual bool split() = 0;

  virtual bool merge() = 0;

  virtual bool cascade(MsgBuffer *buf, Node *parent);
private:

  friend class BTree;

  BTree &_btree;

  bool _dirty;

  bid_t _nid;
};

class InnerNode : Node {
public:
  InnerNode(BTree &btree);

  ~InnerNode();

protected:
  bool split();

  bool cascade(MsgBuffer *buf, Node *parent);

  bool merge();
  
};

class LeafNode : Node {
public:
  LeafNode();
  ~LeafNode();
protected:
  bool cascade(MsgBuffer *buf, Node *parent);

  bool split();

  bool merge();

};

};

#endif

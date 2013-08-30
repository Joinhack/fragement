#ifndef NODE_H
#define NODE_H

#include <vector>
#include "persist/block.h"
#include "msg.h"

#define NID_NONE            0
#define NID_START           (NID_NONE + 2)
#define NID_LEAF_START      (bid_t)((1L << 48) + 1)
#define IS_LEAF(nid)        ((nid) >= NID_LEAF_START)

namespace ndb {

using namespace std;

class BTree;

enum NodeStatus {
  NODE_INIT,
  SKELETONLOADED,
  NODE_LOADED
};

struct NodeSkeleton {
  MsgBuffer *msgBuf;
  Buffer key;
  bid_t nid;
};

class Node {
public:

  virtual ~Node() {};

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

  //virtual bool cascade(MsgBuffer *buf, Node *parent);

  friend class BTree;

  BTree *_btree;

  bool _dirty;

  bid_t _nid;

  NodeStatus _status;
};

class InnerNode : Node {
public:

  typedef vector<NodeSkeleton> SkeletonContainer;

  InnerNode(BTree *btree, bid_t id);

  ~InnerNode();

  bool writeMsg(Msg &msg);

protected:

  //write msg to skeleton msg buffer
  bool writeMsg(Msg &msg, SkeletonContainer::iterator skeleton);

  bool split();

  bool loadMsgBuffer();

  //bool cascade(MsgBuffer *buf, Node *parent);

  bool merge();

private:

  SkeletonContainer::iterator findSkeletonIndex(Buffer &key);

  SkeletonContainer _skeletons;
  
};

class LeafNode : Node {
public:
  LeafNode(BTree *btree, bid_t id);

  ~LeafNode();
protected:
  bool cascade(MsgBuffer *buf, Node *parent);

  bool split();

  bool merge();

};

};

#endif

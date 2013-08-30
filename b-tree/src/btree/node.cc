#include <algorithm>
#include "node.h"
#include "btree.h"

using namespace ndb;
using namespace std;

bool InnerNode::split() {

  return true;
}

bool InnerNode::merge() {
  return true; 
}

struct SkeletonCompare {
  SkeletonCompare(Comparator *comparator): _comparator(comparator) {}
  bool operator()(const NodeSkeleton skeleton, const Buffer b2) const {
    Buffer buf1 = skeleton.key;
    return _comparator->compare(buf1, b2) < 0;
  }
  Comparator *_comparator;
};


InnerNode::SkeletonContainer::iterator InnerNode::findSkeletonIndex(Buffer &key) {
  size_t size = _skeletons.size();
  //test is key in right.
  if(size && _btree->_comparator->compare(key, _skeletons[size - 1].key) >= 0) {
    return _skeletons.end();
  }
  //bin search the lower bound repalce used std::lower_bound
  SkeletonContainer::iterator iter;
  iter = lower_bound(_skeletons.begin(), _skeletons.end(), key, SkeletonCompare(_btree->_comparator));
  return iter;
}


bool InnerNode::loadMsgBuffer() {
  SkeletonContainer::iterator iter;
  for(iter = _skeletons.begin(); iter != _skeletons.end(); iter++) {
    (*iter).msgBuf = new MsgBuffer(_btree->_comparator);
  }
  _status = NODE_LOADED;
  return true;
}

bool InnerNode::writeMsg(Msg &msg, SkeletonContainer::iterator skeleton) {
  (*skeleton).msgBuf->write(msg);
  return true;
}


bool InnerNode::writeMsg(Msg &msg) {
  if(_status != NODE_LOADED)
    loadMsgBuffer();
  writeMsg(msg, findSkeletonIndex(msg._key));  
  return true;
}

InnerNode::InnerNode(BTree *btree, bid_t bid) {
  _btree = btree;
  _nid = bid;
}

InnerNode::~InnerNode() {

}

LeafNode::LeafNode(BTree *btree, bid_t bid) {
  _btree = btree;
  _nid = bid;
}

LeafNode::~LeafNode() {

}


bool LeafNode::split() {

  return true;
}

bool LeafNode::merge() {
  return true; 
}

#include "btree.h"

using namespace ndb;

BTree::BTree(Layout &layout, Comparator *comparator):_layout(layout) {
  _innerNodeBID = NID_START;
  _leafnodeBID = NID_LEAF_START;
  _comparator = comparator;
  _root = NULL;
}


bool BTree::init() {
  _root = (InnerNode*)nextInnerNode();
  return true;
}






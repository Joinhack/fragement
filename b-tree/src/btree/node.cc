#include "node.h"

using namespace ndb;

bool InnerNode::split() {
  
  return true;
}

bool InnerNode::merge() {
  return true; 
}

InnerNode::InnerNode(BTree &btree):_btree(btree) {

}

InnerNode::~InnerNode() {

}
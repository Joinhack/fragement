package tree

import (

)

type NodeInterface interface {
  GetNid() uint64;
  Cascade() bool;
}

type Node struct {
  NodeInterface;
  nid uint64;
}

func (n *Node)GetNid() uint64 {
  return n.nid
}

type Skeleton struct {
  msgCache MsgCache
  offset uint32
}

type InnerNode struct {
  Node
  skeletons []*Skeleton
}

func (node *InnerNode)WriteMsg(msg *Msg) {
  if node.skeletons == nil {
    node.skeletons = make([]*Skeleton, 0, 32)
  }
  
}

func NewInnerNode(nid uint64) *InnerNode {
  var node = new(InnerNode)
  node.nid = nid
  return node
}








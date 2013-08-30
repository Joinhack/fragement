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
  skeletons *[]Skeleton
}

func (node *InnerNode)WriteMsg(msg *Msg) {
  
}







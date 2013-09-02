package tree

import (
  "util"
)

type NStatusType int

const (
  NInit NStatusType = iota
  NSkeletonLoaded
  NLoaded
)

type NodeInterface interface {
  GetNid() uint64;
  cascade(cache *MsgCache, p *InnerNode);
}

type Node struct {
  NodeInterface
  status NStatusType
  tree *Tree
  nid uint64
}

func (n *Node)GetNid() uint64 {
  return n.nid
}

type Skeleton struct {
  msgCache *MsgCache
  key []byte
  nid uint64
  offset uint32
}

type InnerNode struct {
  Node
  msgCount int
  msgSize int
  skeletons []*Skeleton
}

type LeafNode struct {
  Node
  bulk RecordBulk
}

func (node *InnerNode)WriteMsg(msg *Msg) error {
  //lazy init the skeletons
  if node.skeletons == nil {
    node.skeletons = make([]*Skeleton, 0, 32)
  }

  //binary search the low bound
  idx := util.Search(len(node.skeletons) - 1, func(mid int) int {
    return node.tree.opts.Comparator(msg.key, node.skeletons[mid].key)
  })

  node.maybeExtend(idx)

  if node.status == NSkeletonLoaded {
    if err := node.loadMsgCache(idx); err != nil {
      return err
    }
  }
  cache := node.skeletons[idx].msgCache
  if cache.WriteMsg(msg) {
    node.msgCount ++
  }
  oldSize := cache.Size()
  node.msgSize = cache.Size() - oldSize
  node.maybeCascade()
  return nil
}

func (node *InnerNode)findMaxCountIndex() int {
  maxCount := node.tree.opts.MaxMsgCount

  for i := 0; i < len(node.skeletons); i++ {
    if node.skeletons[i].msgCache.Count() > maxCount {
      return i
    }
  }
  return -1
}

func (node *InnerNode)findMaxSizeIndex() int {
  maxSize := node.tree.opts.MaxMsgSize
  for i := 0; i < len(node.skeletons); i++ {
    if node.skeletons[i].msgCache.Size() > maxSize  {
      return i
    }
  }
  return -1
}

func (node *InnerNode)maybeCascade() {
  var idx = -1
  tree := node.tree
  if node.msgCount > tree.opts.MaxMsgCount {
    idx = node.findMaxCountIndex()
  } else if node.msgSize > tree.opts.MaxMsgSize {
    idx = node.findMaxSizeIndex()
  } else {
    return
  }

  cache := node.skeletons[idx].msgCache
  nid := node.skeletons[idx].nid
  var nNode NodeInterface
  if node.skeletons[idx].nid == NilNid {
    nNode = tree.NextLeafNode()
  } else {
    nNode = tree.loadNode(nid)
  }

  nNode.cascade(cache, node)
}

func (node *InnerNode)cascade(cache *MsgCache, parent *InnerNode)  {

}


//extend skeletons
func (node *InnerNode)maybeExtend(idx int) {
  //TODO: I think most time, we used the last index, don't needed extend
  if len(node.skeletons) == idx {
    node.skeletons = append(node.skeletons, new(Skeleton))
    node.skeletons[idx].msgCache = NewMsgCache(node.tree.opts.Comparator)
  }
}

func (node *InnerNode)loadMsgCache(idx int) error {
  node.status = NLoaded
  return nil
}

func NewInnerNode(nid uint64, tree *Tree) *InnerNode {
  var node = new(InnerNode)
  node.nid = nid
  node.tree = tree
  node.msgCount = 0;
  node.msgSize = 0;
  return node
}

func NewLeafNode(nid uint64, tree *Tree) *LeafNode {
  var node = new(LeafNode)
  node.nid = nid
  node.tree = tree
  return node
}

func (node *LeafNode)writeRecord(record *Record) {

}

func (node *LeafNode)cascade(cache *MsgCache, parent *InnerNode)  {
  //node.writeRecord()
}






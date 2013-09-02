package tree

const (
  NilNid uint64 = 0
  InnerNidStart uint64 = 1

  LeafNidStart uint64 = 1 << 48 +1
)

type TreeOptions struct {
  Comparator Comparator
  MaxMsgCount int
  MaxMsgSize int
}

type Tree struct {
  opts TreeOptions
  root *InnerNode
  innerNid uint64
  leafNid  uint64
  nodes map[uint64]NodeInterface
}

func (tree *Tree)Put(key []byte, value []byte) error {
  if value == nil {
    value = []byte{}
  }
  tree.root.WriteMsg(NewMsg(key, value, MsgPut))
  return nil
}

func (tree *Tree)NextLeafNode() *LeafNode {
  tree.innerNid++
  return NewLeafNode(tree.innerNid, tree)
}

func (tree *Tree)NextInnerNode() *InnerNode {
  tree.innerNid++
  return NewInnerNode(tree.innerNid, tree)
}

func (tree *Tree)loadNode(nid uint64) NodeInterface {
  return tree.nodes[nid]
}

func NewTree(opts TreeOptions) *Tree {
  var tree = new(Tree)
  tree.innerNid = InnerNidStart
  tree.leafNid = LeafNidStart
  tree.opts = opts
  tree.root = tree.NextInnerNode()
  tree.innerNid++
  return tree
}
package tree

const (
  InnerNidStart uint64 = 1

  LeafNidStart uint64 = 1 << 48 +1
)

type TreeOptions struct {
  Comparator Comparator
}

type Tree struct {
  opts TreeOptions
  root *InnerNode
  innerNid uint64
  leafNid  uint64
}

func (tree *Tree)Put(key []byte, value []byte) error {
    tree.root.WriteMsg(NewMsg(key, value, MsgPut))
    return nil
}

func NewTree(opts TreeOptions) *Tree {
  var tree = new(Tree)
  tree.innerNid = InnerNidStart
  tree.leafNid = LeafNidStart
  tree.opts = opts
  tree.root = NewInnerNode(tree.innerNid)
  tree.innerNid++
  return tree
}
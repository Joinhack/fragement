package tree

const (
	NilNid        uint64 = 0
	InnerNidStart uint64 = 1

	LeafNidStart uint64 = 1<<48 + 1
)

type TreeOptions struct {
	Comparator            Comparator
	MaxMsgLen             int
	MaxMsgSize            int
	MaxRecordLen          int
	MaxInnerChildNodeSize int
}

type Tree struct {
	opts     TreeOptions
	root     *InnerNode
	innerNid uint64
	leafNid  uint64
	deep     int
	nodes    map[uint64]NodeInterface
}

func (tree *Tree) lockPath(key []byte, path *[]NodeInterface) {
	*path = append(*path, tree.root)
	tree.root.lockPath(key, path)
}

func (tree *Tree) Put(key []byte, value []byte) error {
	if value == nil {
		value = []byte{}
	}
	tree.root.WriteMsg(NewMsg(key, value, MsgPut))
	return nil
}

func (tree *Tree) NextLeafNode() *LeafNode {
	tree.leafNid++
	node := NewLeafNode(tree.leafNid, tree)
	tree.nodes[tree.leafNid] = node
	return node
}

func (tree *Tree) NextInnerNode() *InnerNode {
	tree.innerNid++
	node := NewInnerNode(tree.innerNid, tree)
	tree.nodes[tree.innerNid] = node
	return node
}

func (tree *Tree) loadNode(nid uint64) NodeInterface {
	return tree.nodes[nid]
}

func (tree *Tree) setRoot(root *InnerNode) {
	tree.root = root
	tree.deep++
}

func NewTree(opts TreeOptions) *Tree {
	var tree = new(Tree)
	tree.innerNid = InnerNidStart
	tree.leafNid = LeafNidStart
	tree.opts = opts
	tree.nodes = make(map[uint64]NodeInterface)
	tree.root = NewRoot(tree)
	return tree
}

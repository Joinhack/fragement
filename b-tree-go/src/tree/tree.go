package tree

import (
	"sync"
	"sync/atomic"
)

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
	rwmtx    sync.RWMutex
	nodes    map[uint64]NodeInterface
}

func (tree *Tree) lock() {
	tree.rwmtx.Lock()
}

func (tree *Tree) unlock() {
	tree.rwmtx.Unlock()
}

func (tree *Tree) lockPath(key []byte, path *[]NodeInterface) {
	tree.lock()
	defer tree.unlock()
	tree.root.lock()
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

func (tree *Tree) Del(key []byte) error {
	tree.root.WriteMsg(NewMsg(key, nil, MsgDel))
	return nil
}

func (tree *Tree) Get(key []byte) (error, []byte) {
	value := tree.root.find(key)
	return nil, value
}

func (tree *Tree) NextLeafNode() *LeafNode {
	nid := atomic.AddUint64(&tree.leafNid, 1)
	node := NewLeafNode(nid, tree)
	tree.nodes[nid] = node
	return node
}

func (tree *Tree) NextInnerNode() *InnerNode {
	nid := atomic.AddUint64(&tree.innerNid, 1)
	node := NewInnerNode(nid, tree)
	tree.nodes[nid] = node
	return node
}

func (tree *Tree) loadNode(nid uint64) NodeInterface {
	return tree.nodes[nid]
}

func (tree *Tree) resetRoot() {
	nroot := NewRoot(tree)
	tree.root = nroot
	tree.deep = 0
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

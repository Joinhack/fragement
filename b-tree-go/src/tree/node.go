package tree

import (
	"sort"
)

type NStatusType int

const (
	NInit NStatusType = iota
	NSkeletonLoaded
	NLoaded
)

type NodeInterface interface {
	GetNid() uint64
	lockPath(key []byte, path *[]NodeInterface)
	find(key []byte) []byte
	dump(level int)
	cascade(cache *MsgCache, p *InnerNode)
}

type Node struct {
	NodeInterface
	status NStatusType
	tree   *Tree
	nid    uint64
}

func (n *Node) GetNid() uint64 {
	return n.nid
}

type Skeleton struct {
	msgCache *MsgCache
	key      []byte
	nid      uint64
	offset   uint32
}

type InnerNode struct {
	Node
	msgLen        int
	msgSize       int
	firstNid      uint64
	firstMsgCache *MsgCache
	skeletons     []*Skeleton
}

type LeafNode struct {
	Node
	balancing    bool
	rightLeafNId uint64
	leftLeafNId  uint64
	bulk         *RecordBulk
}

func (node *InnerNode) find(key []byte) []byte {
	idx := node.findSkeletonIdx(key)
	mc := node.getMsgCache(idx)
	msg := mc.find(key)
	if msg != nil && msg.msgType == MsgPut {
		if node.tree.opts.Comparator(msg.key, key) == 0 {
			return msg.value
		}
	}
	cnid := node.childNid(idx)
	if cnid == NilNid {
		return nil
	}
	cnode := node.tree.loadNode(cnid)

	return cnode.find(key)
}

func (node *InnerNode) lockPath(key []byte, path *[]NodeInterface) {
	idx := node.findSkeletonIdx(key)
	child := node.tree.loadNode(node.childNid(idx))
	*path = append(*path, child)
	child.lockPath(key, path)
}

func (node *LeafNode) lockPath(key []byte, path *[]NodeInterface) {
}

func (node *InnerNode) findSkeletonIdx(key []byte) int {
	//binary search the low bound
	idx := sort.Search(len(node.skeletons), func(mid int) bool {
		return node.tree.opts.Comparator(key, node.skeletons[mid].key) < 0
	})
	return idx
}

func (node *InnerNode) getMsgCache(idx int) *MsgCache {
	if idx == 0 {
		return node.firstMsgCache
	} else {
		return node.skeletons[idx-1].msgCache
	}
}

func (node *InnerNode) WriteMsg(msg *Msg) error {
	idx := node.findSkeletonIdx(msg.key)
	if node.status == NSkeletonLoaded {
		if err := node.loadAllMsgCache(); err != nil {
			return err
		}
	}
	cache := node.getMsgCache(idx)
	oldSize := cache.Size()
	if cache.WriteMsg(msg) {
		node.msgLen++
	}
	node.msgSize = node.msgSize + cache.Size() - oldSize
	node.maybeCascade()
	return nil
}

func NewRoot(tree *Tree) *InnerNode {
	root := tree.NextInnerNode()
	root.firstMsgCache = NewMsgCache(tree.opts.Comparator)
	return root
}

func (node *InnerNode) findMaxLenIndex() int {
	maxLen := node.firstMsgCache.Len()
	rs := 0
	for i := 0; i < len(node.skeletons); i++ {
		if node.skeletons[i].msgCache.Len() > maxLen {
			rs = i + 1
		}
	}
	return rs
}

func (node *InnerNode) findMaxSizeIndex() int {
	maxSize := node.firstMsgCache.Size()
	rs := 0
	for i := 0; i < len(node.skeletons); i++ {
		if node.skeletons[i].msgCache.Size() > maxSize {
			rs = i - 1
		}
	}
	return rs
}

func (node *InnerNode) childNid(idx int) uint64 {
	if idx == 0 {
		return node.firstNid
	} else {
		return node.skeletons[idx-1].nid
	}
}

func (node *InnerNode) addSkeleton(key []byte, nid uint64, path *[]NodeInterface) {
	tree := node.tree
	idx := node.findSkeletonIdx(key)
	skeleton := &Skeleton{nid: nid, key: key, msgCache: NewMsgCache(tree.opts.Comparator)}
	//insert
	node.skeletons = append(node.skeletons, nil)
	copy(node.skeletons[idx+1:], node.skeletons[idx:])
	node.skeletons[idx] = skeleton
	if len(node.skeletons)+1 > tree.opts.MaxInnerChildNodeSize {
		node.split(path)
	}
}

func (node *InnerNode) maybeCascade() {
	var idx = -1
	tree := node.tree
	if node.msgLen > tree.opts.MaxMsgLen {
		idx = node.findMaxLenIndex()
	} else {
		return
	}

	cache := node.getMsgCache(idx)

	cnid := node.childNid(idx)
	var nNode NodeInterface
	if cnid == NilNid {
		nNode = tree.NextLeafNode()
		node.setChild(idx, nNode.GetNid())
	} else {
		nNode = tree.loadNode(cnid)
	}

	nNode.cascade(cache, node)
}

func (node *InnerNode) setChild(idx int, cid uint64) {
	if idx == 0 {
		node.firstNid = cid
	} else {
		node.skeletons[idx-1].nid = cid
	}
}

func (node *InnerNode) removeSkeleton(nid uint64, path *[]NodeInterface) {
	if node.firstNid == nid {
		//the last child
		if len(node.skeletons) == 0 {
			if len(*path) == 0 {
				//this root reset the root
				//node.tree.setRoot(root)
			} else {
				pNode := popPath(path).(*InnerNode)
				pNode.removeSkeleton(node.nid, path)
			}
			return
		}
		//shift from second child
		node.firstNid = node.skeletons[0].nid
		node.firstMsgCache = node.skeletons[0].msgCache
		node.msgLen -= node.firstMsgCache.Len()
		node.skeletons = node.skeletons[1:]
	} else {
		idx := sort.Search(len(node.skeletons), func(mid int) bool {
			return node.skeletons[mid].nid != nid
		})
		//remove the skeleton
		node.msgLen -= node.skeletons[idx].msgCache.Len()
		copy(node.skeletons[idx:], node.skeletons[idx+1:])
		node.skeletons = node.skeletons[:len(node.skeletons)-1]
	}

}

func (node *InnerNode) cascade(mc *MsgCache, parent *InnerNode) {
	tree := node.tree
	if node.status == NSkeletonLoaded {
		node.loadAllMsgCache()
	}
	mcLen := mc.Len()
	cacheIdx := 0
	idx := 0
	for cacheIdx < mcLen && idx < len(node.skeletons) {
		msg := mc.cache[cacheIdx]
		skel := node.skeletons[idx]
		if tree.opts.Comparator(msg.key, skel.key) < 0 {
			cache := node.getMsgCache(idx)
			cache.WriteMsg(msg)
			cacheIdx++
		} else {
			idx++
		}
	}

	for cacheIdx < mcLen {
		msg := mc.cache[cacheIdx]
		cache := node.getMsgCache(idx)
		cache.WriteMsg(msg)
		cacheIdx++
	}
	mc.Clear()
	parent.msgLen = parent.msgLen - mcLen + mc.Len()
	node.msgLen += mcLen
	node.maybeCascade()
}

func (node *InnerNode) split(path *[]NodeInterface) {
	mid := len(node.skeletons) / 2
	key := node.skeletons[mid].key
	ni := node.tree.NextInnerNode()
	midSkel := node.skeletons[mid]
	ni.skeletons = append(ni.skeletons, node.skeletons[mid+1:]...)
	ni.firstNid = midSkel.nid
	ni.firstMsgCache = midSkel.msgCache
	node.skeletons = node.skeletons[:len(node.skeletons)-mid]
	niMsgLen := ni.firstMsgCache.Len()

	for _, skel := range ni.skeletons {
		niMsgLen += skel.msgCache.Len()
	}
	ni.msgLen = niMsgLen
	node.msgLen -= niMsgLen

	//it's root now
	if len(*path) == 0 {
		nroot := node.tree.NextInnerNode()
		nroot.firstNid = node.nid
		nroot.firstMsgCache = NewMsgCache(node.tree.opts.Comparator)
		skel := &Skeleton{key: key, msgCache: NewMsgCache(node.tree.opts.Comparator), nid: ni.nid}
		nroot.skeletons = append(nroot.skeletons, skel)
		nroot.msgLen = ni.msgLen + node.msgLen
		node.tree.setRoot(nroot)
	} else {
		pn := popPath(path).(*InnerNode)
		pn.addSkeleton(key, ni.nid, path)
	}

}

func (node *InnerNode) loadAllMsgCache() error {
	node.status = NLoaded
	return nil
}

func NewInnerNode(nid uint64, tree *Tree) *InnerNode {
	var node = new(InnerNode)
	node.nid = nid
	node.tree = tree
	node.msgLen = 0
	node.msgSize = 0
	node.skeletons = make([]*Skeleton, 0, 4)
	return node
}

func NewLeafNode(nid uint64, tree *Tree) *LeafNode {
	var node = new(LeafNode)
	node.nid = nid
	node.tree = tree
	node.balancing = false
	node.bulk = NewRecordBulk()
	return node
}

func popPath(path *[]NodeInterface) NodeInterface {
	l := len(*path)
	node := (*path)[l-1]
	*path = (*path)[:l-1]
	return node
}

func (node *LeafNode) split(arch []byte) {
	if node.balancing {
		return
	}

	if node.bulk.Len() <= 1 ||
		node.bulk.Len() <= node.tree.opts.MaxRecordLen/2 {
		return
	}

	node.balancing = true

	path := make([]NodeInterface, 0, 8)

	node.tree.lockPath(arch, &path)
	if n := popPath(&path); n != node {
		panic("error, the last should be self")
	}

	var nleaf = node.tree.NextLeafNode()

	nleaf.leftLeafNId = node.nid
	if node.rightLeafNId >= LeafNidStart {
		rleaf := node.tree.loadNode(node.rightLeafNId).(*LeafNode)
		rleaf.leftLeafNId = nleaf.nid
	}
	nleaf.rightLeafNId = node.rightLeafNId
	node.rightLeafNId = nleaf.nid
	key := node.bulk.split(nleaf.bulk)

	pNode := popPath(&path).(*InnerNode)

	pNode.addSkeleton(key, nleaf.GetNid(), &path)

	node.balancing = false
}

func (node *LeafNode) merge(arch []byte) {
	if node.balancing {
		return
	}

	path := make([]NodeInterface, 0, 8)

	node.tree.lockPath(arch, &path)

	if popPath(&path) != node {
		panic("error, the last should be self")
	}

	if node.leftLeafNId > LeafNidStart {
		leftNode := node.tree.loadNode(node.leftLeafNId).(*LeafNode)
		leftNode.rightLeafNId = node.rightLeafNId
	}
	if node.rightLeafNId > LeafNidStart {
		rightNode := node.tree.loadNode(node.rightLeafNId).(*LeafNode)
		rightNode.leftLeafNId = node.leftLeafNId
	}
	node.balancing = false
	pNode := popPath(&path).(*InnerNode)
	pNode.removeSkeleton(node.nid, &path)
}

func (node *LeafNode) find(key []byte) []byte {
	idx := sort.Search(node.bulk.Len(), func(mid int) bool {
		return node.tree.opts.Comparator(key, node.bulk.records[mid].key) <= 0
	})

	record := node.bulk.records[idx]
	if node.tree.opts.Comparator(key, record.key) == 0 {
		return record.value
	}
	return nil
}

func (node *LeafNode) cascade(mc *MsgCache, parent *InnerNode) {
	//will sort ascending add all data to new records
	records := make([]*Record, 0, mc.Len()+node.bulk.Len())
	var cacheIdx = 0
	var recordIdx = 0
	arch := mc.cache[0].key
	mLen := mc.Len()
	for cacheIdx < mc.Len() && recordIdx < node.bulk.Len() {
		msg := mc.cache[cacheIdx]
		record := node.bulk.records[recordIdx]

		if rs := node.tree.opts.Comparator(msg.key, record.key); rs < 0 {
			if msg.msgType == MsgPut {
				records = append(records, &Record{msg.key, msg.value})
			}
			cacheIdx++
		} else if rs > 0 {
			records = append(records, record)
			recordIdx++
		} else {
			if msg.msgType == MsgPut {
				records = append(records, &Record{msg.key, msg.value})
			}
			cacheIdx++
			recordIdx++
		}
	}

	for cacheIdx < mc.Len() {
		msg := mc.cache[cacheIdx]
		records = append(records, &Record{msg.key, msg.value})
		cacheIdx++
	}

	for recordIdx < node.bulk.Len() {
		record := node.bulk.records[recordIdx]
		records = append(records, record)
		recordIdx++
	}

	mc.Clear()

	parent.msgLen = parent.msgLen - mLen + mc.Len()
	node.bulk.records = records
	if node.bulk.Len() == 0 {
		node.merge(arch)
	}
	if node.bulk.Len() > node.tree.opts.MaxRecordLen {
		node.split(arch)
	}

}

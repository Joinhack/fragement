package tree

import (
	"math/rand"
	"strconv"
	"testing"
)

func byteCompare(k1, k2 []byte) int {
	return int(k1[0]) - int(k2[0])
}

func TestMsgCache(t *testing.T) {
	var node InnerNode
	t.Log(node.GetNid())
	var mc = NewMsgCache(StrComparator)
	randint := make([]byte, 0)
	for i := 0; i < 1; i++ {
		b := byte(rand.Intn(255))
		randint = append(randint, b)
		s := string(strconv.AppendInt(nil, int64(b), 10))
		mc.WriteMsg(NewMsg([]byte(s), []byte(s), MsgPut))
	}

	for _, msg := range mc.cache {
		t.Log(msg.key[0])
	}

	for _, k := range randint {
		s := string(strconv.AppendInt(nil, int64(k), 10))
		mc.WriteMsg(NewMsg([]byte(s), []byte(s), MsgDel))
	}
	t.Log("After Del, Cache Size,", mc.Len())
	if mc.Len() != 1 {
		panic("should be zero")
	}
	mc.Clear()
}

func TestTreePut(t *testing.T) {
	var opts = TreeOptions{MaxMsgLen: 5, MaxRecordLen: 4, MaxInnerChildNodeSize: 4}
	opts.Comparator = StrComparator
	tree := NewTree(opts)
	for i := 1; i <= 10000; i++ {
		tree.Put(strconv.AppendInt(nil, int64(i), 10), strconv.AppendInt(nil, int64(i), 10))
	}
	println(tree.deep)
	for i := 1; i <= 10000; i++ {
		_, v := tree.Get(strconv.AppendInt(nil, int64(i), 10))
		if v == nil {
			panic(v)
		}
		t.Log(string(v))
	}
}

func TestTreeRandPut(t *testing.T) {
	var opts = TreeOptions{MaxMsgLen: 20, MaxRecordLen: 10, MaxInnerChildNodeSize: 10}
	opts.Comparator = StrComparator
	tree := NewTree(opts)
	randint := make([]int, 0)
	for i := 1; i <= 5000; i++ {
		r := rand.Intn(5000)
		randint = append(randint, r)
		tree.Put(strconv.AppendInt(nil, int64(r), 10), strconv.AppendInt(nil, int64(i), 10))
	}
	for _, r := range randint {
		_, v := tree.Get(strconv.AppendInt(nil, int64(r), 10))
		if v == nil {
			panic(v)
		}
		t.Log(string(v))
	}
}

func TestTreePutDel(t *testing.T) {
	var opts = TreeOptions{MaxMsgLen: 20, MaxRecordLen: 10, MaxInnerChildNodeSize: 10}
	opts.Comparator = StrComparator
	tree := NewTree(opts)
	for i := 1; i <= 100; i++ {
		tree.Put(strconv.AppendInt(nil, int64(i), 10), strconv.AppendInt(nil, int64(i), 10))
	}
	for i := 1; i <= 100; i++ {
		tree.Del(strconv.AppendInt(nil, int64(i), 10))
	}
	for i := 1; i <= 100; i++ {
		_, v := tree.Get(strconv.AppendInt(nil, int64(i), 10))

		if v != nil {
			panic(string(v))
		}
	}
	t.Log("After del, deep:", tree.deep)
}

func TestSlice(t *testing.T) {
	var c []int = make([]int, 0, 20)
	for i := 0; i < 10; i++ {
		c = append(c, i)
	}
	c = append(c, 0)
	copy(c[6:], c[5:])
	c[5] = 10
	t.Log(c)
}

func TestInnerNode(t *testing.T) {
	n := []int{1, 2, 3}
	t.Log(n[1:], n[:1])
}

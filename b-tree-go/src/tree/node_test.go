package tree

import (
  "testing"
  "math/rand"
)

func IntComparator(b1 []byte, b2 []byte) int {
  return int(b1[0]) - int(b2[0])
}

func TestMsgCache(t *testing.T) {
  var node InnerNode
  t.Log(node.GetNid())
  var mc = NewMsgCahe(IntComparator)

  for i := 0; i < 255; i++  {
    b := byte(rand.Intn(255))
    mc.WriteMsg(&Msg{[]byte{b}, nil, MsgPut})
  }
  for _, msg := range(mc.cache) {
    t.Log(msg.key[0])
  }

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
  var node InnerNode;
  t.Log(node.nid)
}
package tree

import (
	"util"
)

type MsgType int

const (
	MsgPut MsgType = iota
	MsgDel
)

type Msg struct {
	key     []byte
	value   []byte
	msgType MsgType
}

func (msg *Msg) Size() int {
	return len(msg.key) + len(msg.value)
}

type Comparator func(b1 []byte, b2 []byte) int

func strcmp(a, b string) int {
	min := len(b)
	if len(a) < len(b) {
		min = len(a)
	}
	diff := 0
	for i := 0; i < min && diff == 0; i++ {
		diff = int(a[i]) - int(b[i])
	}
	if diff == 0 {
		diff = len(a) - len(b)
	}
	return diff
}

func StrComparator(b1 []byte, b2 []byte) int {
	return strcmp(string(b1), string(b2))
}

type MsgCache struct {
	cache      []*Msg
	size       int
	comparator Comparator
}

func NewMsg(key []byte, value []byte, msgType MsgType) *Msg {
	var msg = new(Msg)
	msg.key = key
	msg.value = value
	msg.msgType = msgType
	return msg
}

func (mc *MsgCache) Size() int {
	return mc.size
}

func (mc *MsgCache) Len() int {
	return len(mc.cache)
}

func (mc *MsgCache) Clear() {
	mc.cache = mc.cache[0:0]
}

//return true if add, return false if replace
func (mc *MsgCache) WriteMsg(msg *Msg) bool {

	if mc.cache == nil {
		mc.cache = make([]*Msg, 0, 8)
	}

	min := util.Search(len(mc.cache)-1, func(mid int) int {
		return mc.comparator(msg.key, mc.cache[mid].key)
	})
	//if cache contain the key. replace it
	if min < len(mc.cache) && mc.comparator(msg.key, mc.cache[min].key) == 0 {
		mc.cache[min].value = msg.value
		mc.size += (msg.Size() - mc.cache[min].Size())
		return false
	} else {
		//insert value to slice
		mc.cache = append(mc.cache, nil)
		copy(mc.cache[min+1:], mc.cache[min:])
		mc.cache[min] = msg
		mc.size += msg.Size()
		return true
	}
}

func NewMsgCache(comparator Comparator) *MsgCache {
	var mc MsgCache
	mc.comparator = comparator
	mc.size = 0
	//init the default cache size
	mc.cache = nil
	return &mc
}

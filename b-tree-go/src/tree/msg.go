package tree

import (
  a "util/algorithm"
)

type MsgType int

const (
  MsgPut MsgType = iota
  MsgDel
)

type Msg struct {
  key *[]byte
  value *[]byte
  msgType MsgType
}


type Comparator func(b1 *[]byte, b2 *[]byte) int


type MsgCache struct {
  cache []*Msg
  comparator Comparator
}

func (mc *MsgCache) WriteMsg(msg *Msg) {

  if mc.cache == nil {
    mc.cache = make([]*Msg, 0, 32)
  }

  
  min := a.Search(len(mc.cache), func(mid int) bool {return mc.comparator(msg.key, mc.cache[mid].key) <= 0})
  //if cache contain the key. replace it
  if min < len(mc.cache) && mc.comparator(msg.key, mc.cache[min].key) == 0 {
    mc.cache[min].value = msg.value
  } else {
    //insert value to slice
    mc.cache = append(mc.cache, nil)
    copy(mc.cache[min + 1:], mc.cache[min:])
    mc.cache[min] = msg
  }
}

func CreateMsgCahe(comparator Comparator) MsgCache {
  var mc MsgCache
  mc.comparator = comparator
  //init the default cache size
  mc.cache = nil
  return mc
}


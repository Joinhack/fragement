package tree

import (
  "sort"
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

func (mc *MsgCache) Write(msg *Msg) {

  //bin search find the low bound
  // for max >= min {
  //   mid := (max + min)/2
  //   rs := mc.comparator(msg.key, mc.cache[mid].key)
  //   if rs > 0 {
  //     min = mid + 1
  //   } else if rs < 0 {
  //     max = mid - 1
  //   } else {
  //     min = mid
  //     break;
  //   }
  // }
  min := sort.Search(len(mc.cache), func(mid int) bool {return mc.comparator(msg.key, mc.cache[mid].key) <= 0})
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
  mc.comparator = comparator;
  //init the default cache size
  mc.cache = make([]*Msg,0,32)
  return mc
}


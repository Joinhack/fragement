#ifndef MSG_H
#define MSG_H
#include <vector>
#include "persist/block.h"

namespace ndb {

using namespace std;

struct Comparator {
  virtual int compare(Buffer b1, Buffer b2) = 0;
};

template<typename T>
struct RawComparator : Comparator {
public:
  int compare(Buffer b1,Buffer b2) {
    return *((T*)b1.raw()) - *((T*)b2.raw());
  }
};

enum MsgType {
  INIT = 0,
  PUT,
  DEL
};

struct Msg {
public:
  Msg(Buffer key, Buffer value):_key(key), _value(value) {}

  void setType(MsgType t) {
    _type = t;
  }

  MsgType getType() {
    return _type;
  }

  //marshal key and value to block
  bool write(BlockWriter &bw) {
    if(!bw.writeBuffer(_key)) return false;
    if(!bw.writeBuffer(_value)) return false;
    return true;
  }

  //unmarshal key and value from block
  bool read(BlockReader &br) {
    if(!br.readBuffer(_key)) return false;
    if(!br.readBuffer(_value)) return false;
    return true;
  }

  size_t size() {
    size_t s = _key.size() + 4;
    if(_type == PUT) {
      s += _value.size() + 4;
    }
    return s;
  }

  MsgType _type;
  Buffer _key;
  Buffer _value;
};

struct MsgCompare {
  MsgCompare(Comparator *comparator): _comparator(comparator) {}
  bool operator()(Msg msg, Buffer b2) const {
    return _comparator->compare(msg._key, b2) < 0;
  }
  Comparator *_comparator;
};


class MsgBuffer {
public:

  MsgBuffer(Comparator *comparator): _comparator(comparator) {}

  typedef vector<Msg> ContainerType;
  typedef ContainerType::iterator Iterator;

  bool write(Msg &msg);

  MsgBuffer() {
    _container.reserve(32);
  }

private:

  ContainerType _container;

  Comparator *_comparator;
};

};

#endif 


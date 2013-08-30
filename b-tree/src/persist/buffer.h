#ifndef BUFFER_H
#define BUFFER_H

#include <string>
#include <string.h>

namespace ndb {

using namespace std;

class Buffer {
public:
  Buffer(): _buf(NULL), _size(0) {}

  Buffer(const string &s): _buf((void*)s.c_str()), _size(s.length()) {}

  Buffer(void *b, size_t len): _buf(b), _size(len) {}

  void *raw() {
    return _buf;
  }

  Buffer clone() {
    Buffer buff;
    buff._buf = static_cast<void*>(new char[_size]);
    buff._size = _size;
    memcpy(buff._buf, _buf, _size);
    return buff;
  }

  void destroy() {
    delete []static_cast<char*>(_buf);
  }

  size_t size() {
    return _size;
  }

private:
  void *_buf;
  size_t _size;
};

};

#endif


#ifndef BUFFER_H
#define BUFFER_H

#include <string>

class Buffer {
public:
  Buffer(const char *s): _buf(s), _size(strlen(s)) {}

  Buffer(const std::string &s): _buf(s.c_str()), _size(s.length()) {}

  Buffer(const char *s, size_t len): _buf(s), _size(len) {}

  const char *raw() {
    return _buf;
  }

  size_t size() {
    return _size;
  }
private:
  const char *_buf;
  size_t _size;
};

#endif


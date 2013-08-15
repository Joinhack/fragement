#ifndef BLOCK_H
#define BLOCK_H
#include <stdint.h>
#include <assert.h>
#include "buffer.h"

typedef uint64_t bid_t;

class Block {
public:
  Block(Buffer &buffer, size_t offset):_buffer(buffer), _size(0), _begin(offset) {
  }

  size_t capacity() {
    return _buffer.size() - _begin;
  }

  size_t remain() {
    return _buffer.size() - _begin - _size ;
  }

  size_t size() {
    return _size;
  }


private:
  friend class BlockWriter;
  friend class BlockReader;
  size_t _begin;
  size_t _size;
  Buffer& _buffer;
};

class BlockWriter {
public:
  BlockWriter(Block& block):_block(block), _offset(0) {}

  bool writeBool(bool i) {
    return writeRawType(i);
  }

  bool writeUInt8(uint8_t i) {
    return writeRawType(i);
  }

  bool writeUInt16(uint16_t i) {
    return writeRawType(i);
  }

  bool writeUInt32(uint32_t i) {
    return writeRawType(i);
  }

  bool writeUInt64(uint64_t i) {
    return writeRawType(i);
  }

  bool writeBuffer(Buffer buffer) {
    char *p;
    if(!_getWriteRaw(buffer.size(), p))
      return false;
    memcpy((void*)p, (void*)buffer.raw(), buffer.size());
    return true;
  }

  bool seek(size_t offset) {
    if(offset > _block.capacity())
      return false;
    _offset = offset;
    return true;
  }
  
  //write the raw type
  template<typename T>
  bool writeRawType(T i) {
    char *p;
    if(!_getWriteRaw(sizeof(T), p))
      return false;
    *(T*)p = i;
    return true;
  }
private:
  bool _getWriteRaw(size_t l, char* &p) {
    assert(_offset < _block.capacity());
    if((_offset + l > _block.capacity()))
      return false;

    p = (char*)_block._buffer.raw() + _block._begin + _offset;
    _offset += l;

    //if overwrite the block don't set the block size.
    if(_offset > _block.size()) {
      _block._size = _offset;
    }
    return true;
  }

  //writer offset
  size_t _offset;
  Block& _block;
};

class BlockReader {
public:
  BlockReader(Block &block): _block(block), _offset(0) {}

  bool readBool(bool &i) {
    return _readRaw(i);
  }

  bool readUInt8(uint8_t &i) {
    return _readRaw(i);
  }

  bool readUInt16(uint16_t &i) {
    return _readRaw(i);
  }

  bool readUInt32(uint32_t &i) {
    return _readRaw(i);
  }

  bool readUInt64(uint64_t &i) {
    return _readRaw(i);
  }

  bool readBuffer(Buffer &b) {
    char *p;
    assert(_offset < _block.capacity());
    if(!_getReadRaw(b.size(), p))
      return false;
    memcpy((void*)b.raw(), p, b.size());
    return true;
  }

  bool seek(size_t offset) {
    if(offset > _block.capacity())
      return false;
    _offset = offset;
    return true;
  }
private:
  template<typename T>
  bool _readRaw(T &i) {
    char *p;
    if(!_getReadRaw(sizeof(T), p))
      return false;
    i = *(T*)p;
    return true;
  }

  bool _getReadRaw(size_t l, char* &p) {
    assert(_offset < _block.capacity());
    if((_offset + l > _block.capacity()))
      return false;

    p = (char*)_block._buffer.raw() + _block._begin + _offset;
    _offset += l;
    return true;
  }

  Block& _block;
  size_t _offset;
};

#endif /**BLOCK_H*/

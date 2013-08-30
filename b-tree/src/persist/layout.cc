#include <stdlib.h>
#include <assert.h>
#include "layout.h"
#include "util/log.h"


using namespace ndb;

Layout::Layout(AIOFile &file): _file(file), _offset(0), _superBlock(new SuperBlock) {
}

Layout::~Layout() {
  if(_superBlock->meta)
    delete _superBlock->meta;
  delete _superBlock;
}

bool Layout::init(bool create) {
  if(create) {
    if(!flushSuperBlock()) return false;
  } else {
    if(!loadSuperBlock()) return false;
  }
  if(!init()) return false;
  return true;
}

bool Layout::init() {
  if(_superBlock->meta) {
    _offset = _superBlock->meta->offset + _superBlock->meta->size;
  } else {
    _offset = SUPBLOCK_SIZE;
  }
  return true;
}

bool Layout::writeSuperBlock(Block &b) {
  BlockWriter bw = BlockWriter(b);
  if(!bw.writeUInt32(_superBlock->magic_number)) return false;
  if(!bw.writeUInt8(_superBlock->major_version)) return false;
  if(!bw.writeUInt8(_superBlock->minor_version)) return false;
  if(_superBlock->meta) {
    if(!bw.writeBool(true)) return false;
    if(!writeBlockMeta(bw, _superBlock->meta)) return false;
  } else
    if(!bw.writeBool(false)) return false;
  if(!bw.writeUInt32(_superBlock->end_constant)) return false;
  return true;
}

bool Layout::readSuperBlock(Block &b) {
  BlockReader br = BlockReader(b);
  if(!br.readUInt32(_superBlock->magic_number)) return false;
  if(!br.readUInt8(_superBlock->major_version)) return false;
  if(!br.readUInt8(_superBlock->minor_version)) return false;
  bool hasMeta;
  if(!br.readBool(hasMeta)) return false;
  if(hasMeta) {
    if(!_superBlock->meta) _superBlock->meta = new BlockMeta();
    if(!readBlockMeta(br, _superBlock->meta)) return false;
  }
  if(!br.readUInt32(_superBlock->end_constant)) return false;
  return true;
}

bool Layout::writeBlockMeta(BlockWriter &bw, BlockMeta *meta) {
  if(!bw.writeUInt64(meta->offset)) return false;
  if(!bw.writeUInt64(meta->size)) return false;
  return true;
}

bool Layout::readBlockMeta(BlockReader &br, BlockMeta *meta) {
  if(!br.readUInt64(meta->offset)) return false;
  if(!br.readUInt64(meta->size)) return false;
  return true;
}

bool Layout::flushSuperBlock() {
  Buffer b = newBuffer(SUPBLOCK_SIZE);
  Block block(b, 0);
  if(!writeSuperBlock(block)) return false;
  //sync write superblock
  if(!write(0, b)) return false;
  freeBuffer(b);
  return true;
}

bool Layout::writeIndex(Block &block) {
  IndexType::iterator iter;
  BlockWriter bw(block);
  //acquire the index lock
  ScopeLock lock(_idxMutex);
  bw.writeUInt64(_index.size());
  for(iter = _index.begin(); iter != _index.end(); iter++) {
    if(!bw.writeUInt64(iter->first)) return false;
    if(!writeBlockMeta(bw, iter->second)) return false;
  }
  return true;
}

bool Layout::readIndex(Block &block) {
  IndexType::iterator iter;
  BlockReader br(block);
  uint64_t size, bid;
  size_t i;
  //acquire the index lock
  ScopeLock lock(_idxMutex);
  if(!br.readUInt64(size)) return false;
  for(i = 0; i < size; i++) {
    if(!br.readUInt64(bid)) return false;
    BlockMeta *meta = new BlockMeta();
    if(!readBlockMeta(br, meta)) return false;
    _index[bid] = meta;
  }
  return true;
}

bool Layout::write(size_t offset, Buffer &buffer) {
  ScopeLock lock(_mutex);
  AIOStatus status = _file.write(offset, buffer);
  if(!status.success)
    LOG_ERROR("fail write size:%llu to offset:%llu", buffer.size(), offset);
  return status.success;
}

bool Layout::read(size_t offset, Buffer &buffer) {
  ScopeLock lock(_mutex);
  AIOStatus status = _file.read(offset, buffer);
  if(!status.success)
    LOG_ERROR("fail read size:%llu from offset:%llu", buffer.size(), offset);
  return status.success;
}

Buffer Layout::newBuffer(size_t size) {
  void *p;
  size_t l = PAGE_ROUND_UP(size);
  int rs = posix_memalign(&p, PAGE_SIZE, l);
  assert(rs == 0);
  return Buffer((char*)p, l);
}

void Layout::freeBuffer(Buffer &b) {
  free(b.raw());
}

bool Layout::loadSuperBlock() {
  Buffer b = newBuffer(PAGE_SIZE);
  Block block(b, 0);
  //sync read superblock.
  if(!read(0, b)) return false;
  if(!readSuperBlock(block)) return false;
  freeBuffer(b);
  return true;
}

size_t Layout::getOffset(size_t s) {
  //TODO: get offset from fragment
  ScopeLock lock(_mutex);
  size_t offset = _offset;
  _offset += s;
  return offset;
}

bool Layout::flushIndex() {
  size_t idxLen = getIndexLength();
  Buffer buffer = newBuffer(idxLen);
  Block block(buffer, 0);
  if(!writeIndex(block)) return false;
  size_t offset = getOffset(buffer.size());

  if(!write(offset, buffer)) return false;
  if(!_superBlock->meta) {
    _superBlock->meta = new BlockMeta();
  }

  ScopeLock lock(_idxMutex);
  _superBlock->meta->offset = offset;
  _superBlock->meta->size = buffer.size();

  LOG_TRACE("flush index success");
  freeBuffer(buffer);
  return true;
}

bool Layout::addFreeBlock(FreeBlock fb) {
  return true;
}



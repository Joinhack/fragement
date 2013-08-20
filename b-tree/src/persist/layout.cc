#include <stdlib.h>
#include "layout.h"


using namespace ndb;

Layout::Layout(AIOFile &file): _file(file), _offset(0), _superBlock(new SuperBlock) {

}

Layout::~Layout() {
  delete _superBlock;
}

bool Layout::init(bool create) {
  if(create) {
    if(!flushSuperBlock()) return false;
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
  Buffer b = newBuffer(PAGE_SIZE);
  Block block(b, 0);
  if(!writeSuperBlock(block)) return false;
  _file.write(0, b);
  freeBuffer(b);
  return true;
}

bool Layout::loadSuperBlock() {
  Buffer b = newBuffer(PAGE_SIZE);
  Block block(b, 0);
  AIOStatus status = _file.read(0, b);
  if(!status.success) return false;
  if(!readSuperBlock(block)) return false;
  freeBuffer(b);
  return true;
}

bool Layout::flushIndex() {
  return false;
}

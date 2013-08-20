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
    if(!flushSuperBlock())
      return false;

  }
  return true;
}

bool Layout::writeSuperBlock(Block &b) {
  BlockWriter bw = BlockWriter(b);
  if(!bw.writeUInt32(_superBlock->magic_number)) return false;
  if(!bw.writeUInt8(_superBlock->major_version)) return false;
  if(!bw.writeUInt8(_superBlock->minor_version)) return false;
  if(!bw.writeUInt32(_superBlock->end_constant)) return false;
  return true;
}

bool Layout::loadSuperBlock(Block &b) {
  BlockReader br = BlockReader(b);
  if(!br.readUInt32(_superBlock->magic_number)) return false;
  if(!br.readUInt8(_superBlock->major_version)) return false;
  if(!br.readUInt8(_superBlock->minor_version)) return false;
  if(!br.readUInt32(_superBlock->end_constant)) return false;
  return true;
}

bool Layout::flushSuperBlock() {
  return false;
}

bool Layout::flushIndex() {
  return false;
}

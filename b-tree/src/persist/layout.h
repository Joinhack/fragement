#ifndef LAYOUT_H
#define LAYOUT_H

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include "block.h"
#include "aio_file.h"

namespace ndb {

struct BlockMeta {
  uint64_t offset;
  uint64_t size;
};

#define NDB_MAGIC 0x6e646200

//the data file head.
struct SuperBlock {
  SuperBlock() {
    magic_number = NDB_MAGIC;
    major_version = 0x1;
    minor_version = 0x1;
    end_constant = 0xFFFFFFFF;
    meta = NULL;
  }
  //MAGIC NUMBER
  uint32_t magic_number;
  uint8_t major_version;
  uint8_t minor_version;
  uint32_t end_constant;
  //index block meta
  BlockMeta *meta;
};

#define PAGE_SIZE 4096

#define PAGE_ROUND_UP(x) (((x) + PAGE_SIZE-1)&(~(PAGE_SIZE-1)))

#define PAGE_ROUND_DOWN(x) (((x) + PAGE_SIZE-1)&(~(PAGE_SIZE-1)))

class Layout {
public:
  Layout(AIOFile &file);

  static Buffer newBuffer(size_t size) {
    void *p;
    size_t l = PAGE_ROUND_UP(size);
    int rs = posix_memalign(&p, PAGE_SIZE, l);
    assert(rs == 0);
    return Buffer((char*)p, l);
  }

  bool init(bool create);

  bool flushSuperBlock();

  bool loadSuperBlock();

  bool flushIndex();

  static void freeBuffer(Buffer &b) {
    free((void*)b.raw());
  }

  SuperBlock *getSuperBlock() {
    return _superBlock;
  }

  ~Layout();
protected:

  bool readBlockMeta(BlockReader &br, BlockMeta *meta);

  bool writeBlockMeta(BlockWriter &br, BlockMeta *meta);

  bool writeSuperBlock(Block &b);

  bool readSuperBlock(Block &b);

private:
  AIOFile &_file;
  //file offset, always point the end of file.
  size_t _offset;
  SuperBlock *_superBlock;
};

};

#endif

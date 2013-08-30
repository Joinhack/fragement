#ifndef LAYOUT_H
#define LAYOUT_H

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <map>
#include <vector>
#include "block.h"
#include "sys/posix_sys.h"
#include "aio_file.h"

namespace ndb {

using namespace std;

struct BlockMeta {
  uint64_t offset;
  uint64_t size;
};

#define NDB_MAGIC 0x6e6462FF

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

#define SUPBLOCK_SIZE PAGE_SIZE

#define PAGE_ROUND_UP(x) (((x) + PAGE_SIZE-1)&(~(PAGE_SIZE-1)))

#define PAGE_ROUND_DOWN(x) (((x) + PAGE_SIZE-1)&(~(PAGE_SIZE-1)))

class Layout {
public:

  Layout(AIOFile &file);

  //alloc aligned mem buffer
  static Buffer newBuffer(size_t size);

  //free buffer from newBuffer
  static void freeBuffer(Buffer &b);

  bool init(bool create);

  //sync write superblock to file
  bool flushSuperBlock();

  //sync read superblock from file
  bool loadSuperBlock();

  //sync write index from file
  bool flushIndex();

  //sync read index from file
  bool loadIndex();

  SuperBlock *getSuperBlock() {
    return _superBlock;
  }

  ~Layout();
protected:
  //set the _offset 
  bool init();

  //read block meta from block
  bool readBlockMeta(BlockReader &br, BlockMeta *meta);

  //write block meta to block
  bool writeBlockMeta(BlockWriter &br, BlockMeta *meta);

  //write superblock to block
  bool writeSuperBlock(Block &b);

  //write index to block
  bool writeIndex(Block &b);

  //read index from block
  bool readIndex(Block &b);

  //write buffer to file
  bool write(size_t offset, Buffer &buffer);

  //read buffer from file
  bool read(size_t offset, Buffer &buffer);

  //read superblock from block
  bool readSuperBlock(Block &b);

  //get index persist length, it should be index size + sizeof(uint64_t)
  size_t getIndexLength() {
    return _index.size() * (sizeof(uint64_t) + sizeof(BlockMeta)) + sizeof(uint64_t);
  };

  //get offset for write
  size_t getOffset(size_t s);

  //not used block info
  struct FreeBlock {
    uint64_t offset;
    uint64_t size;
  };

  typedef map<bid_t, BlockMeta*> IndexType;

  typedef vector<FreeBlock> FreeBlockListType;

  bool addFreeBlock(FreeBlock fb);

private:

  //index mutex
  Mutex _idxMutex;

  Mutex _mutex;

  Mutex _freeBlockMutex;

  IndexType _index;

  AIOFile &_file;

  FreeBlockListType _freeBlocks;

  //file offset, always point the end of file.
  size_t _offset;

  SuperBlock *_superBlock;
};

};

#endif

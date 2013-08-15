#ifndef LAYOUT_H
#define LAYOUT_H

#include <stdint.h>

typedef struct block_meta {
  size_t offset;
  size_t size;
} block_meta;

//the data file head.
typedef struct super_block {
  //MAGIC NUMBER
  uint64_t magic_number;
  uint8_t major_version;
  uint8_t minor_version;
  uint64_t end_constant;
  block_meta *meta;
} super_block;

typedef struct layout {
  super_block *super_block;

} layout;

int write_super_block(layout* l);

#endif

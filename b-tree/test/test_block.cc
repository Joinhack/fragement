#include <gtest/gtest.h>
#include "persist/block.h"

TEST(Block, readwrite) {
  char buf[128] = {0};
  Buffer buffer = Buffer(buf, sizeof(buf));
  Block b = Block(buffer, 0);
  BlockWriter bw = BlockWriter(b);
  bw.seek(0);
  bw.writeUInt8(1);
  EXPECT_TRUE(buf[0] == 1);
  bw.writeUInt16(0xfebc);
  EXPECT_TRUE(*(uint16_t*)(buf + 1) == 0xfebc);

  EXPECT_TRUE(bw.writeUInt32(0x930efebc));
  EXPECT_TRUE(*(uint32_t*)(buf + 1 + 2) == 0x930efebc);

  EXPECT_TRUE(bw.writeUInt64(0x9396820230efebc2L));
  EXPECT_TRUE(*(uint64_t*)(buf + 1 + 2 + 4) == 0x9396820230efebc2L);

  Buffer b2 = Buffer("asdasdasd121asdasd231sdasdasd");
  EXPECT_TRUE(bw.writeBuffer(b2));
  EXPECT_TRUE(memcmp(buf + 1 + 2 + 4 + 8, b2.raw(), b2.size()) == 0);


  

  BlockReader br = BlockReader(b);
  uint8_t i1;
  EXPECT_TRUE(br.readUInt8(i1));
  EXPECT_EQ(i1, 1);

  uint16_t i2;
  EXPECT_TRUE(br.readUInt16(i2));
  EXPECT_EQ(i2, 0xfebc);

  uint32_t i4;
  EXPECT_TRUE(br.readUInt32(i4));
  EXPECT_EQ(i4, 0x930efebc);

  uint64_t i8;
  EXPECT_TRUE(br.readUInt64(i8));
  EXPECT_EQ(i8, 0x9396820230efebc2L);

  char buff2[32] = {0};
  Buffer b3 = Buffer(buff2, sizeof(buff2));
  EXPECT_TRUE(br.readBuffer(b3));
  EXPECT_TRUE(memcmp(b2.raw(), b3.raw(), b2.size()) == 0);

  EXPECT_TRUE(bw.seek(50));
  bw.writeUInt16(0xfebc);
  EXPECT_TRUE(*(uint16_t*)(buf + 50) == 0xfebc);

  EXPECT_TRUE(bw.seek(50));
  bw.writeUInt16(0xfebc);
  EXPECT_EQ(b.size(), 52);


}

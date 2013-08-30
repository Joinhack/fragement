#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include <gtest/gtest.h>

#include "persist/aio_file.h"
#include "sys/atomic.h"
#include "persist/layout.h"

using namespace ndb;

static uint32_t wc = 0;
static uint32_t rc = 0;

static void write_complete(void *ctx, AIOStatus status) {
  atomic_add_uint32(&wc, 1);
  EXPECT_EQ(4096, status.rs);
  EXPECT_TRUE(status.success);
}

static void read_complete(void *ctx, AIOStatus status) {
  atomic_add_uint32(&rc, 1);
  EXPECT_EQ(4096, status.rs);
  EXPECT_TRUE(status.success);
}

TEST(AIOFile, readwrite) {

  AIOFile file = AIOFile("/tmp/aiotest");
  EXPECT_TRUE(file.open());
  Buffer buffer[1000];
  wc = 0;
  rc = 0;
  for(int i = 1; i <= 1000; i++) {
    buffer[i - 1] = Layout::newBuffer(4096);
    memset((void*)buffer[i - 1].raw(), i, buffer[i - 1].size());
    file.write((i - 1)*buffer[i - 1].size(), buffer[i - 1], write_complete, NULL);
  }
  while(wc < 1000) continue;
  Buffer expectBuffer = Layout::newBuffer(4096);
  for(int i = 1; i <= 1000; i++) {
    memset((void*)expectBuffer.raw(), i, expectBuffer.size());
    memset((void*)buffer[i - 1].raw(), 0, buffer[i - 1].size());
    file.read((i - 1)*buffer[i - 1].size(), buffer[i - 1], read_complete, NULL);
    while(rc < i) continue;
    EXPECT_EQ(memcmp((void*)expectBuffer.raw(), (void*)buffer[i - 1].raw(), buffer[i - 1].size()), 0);
  }
  while(rc < 1000) continue;
  for(int i = 0; i < 1000; i++)
    Layout::freeBuffer(buffer[i]);
  Layout::freeBuffer(expectBuffer);
  file.remove();
}

TEST(AIOFile, skipreadwrite) {
  AIOFile file = AIOFile("/tmp/aiotest");
  EXPECT_TRUE(file.open());
  Buffer buffer = Layout::newBuffer(4096);
  wc = 0;
  rc = 0;
  file.truncate(40960);
  memset((void*)buffer.raw(), 100, buffer.size());
  file.write(4096, buffer, write_complete, NULL);
  while(wc < 1) continue;

  memset((void*)buffer.raw(), 0, buffer.size());
  file.read(4096, buffer, read_complete, NULL);
  while(rc < 1) continue;
  Buffer expectBuffer = Layout::newBuffer(4096);
  memset((void*)expectBuffer.raw(), 100, expectBuffer.size());
  EXPECT_EQ(memcmp((void*)expectBuffer.raw(), (void*)buffer.raw(), buffer.size()), 0);

  Layout::freeBuffer(expectBuffer);
  Layout::freeBuffer(buffer);
  file.remove();
}

TEST(AIOFile, syncreadwrite) {
  AIOFile file = AIOFile("/tmp/aiotest");
  EXPECT_TRUE(file.open());
  Buffer buffer = Layout::newBuffer(4096);

  EXPECT_TRUE(file.truncate(4096*2));

  memset((void*)buffer.raw(), 100, buffer.size());
  AIOStatus status = file.write(100, buffer);
  EXPECT_EQ(status.success, true);
  EXPECT_EQ(status.rs, 4096);

  memset((void*)buffer.raw(), 0, buffer.size());
  status = file.read(100, buffer);
  EXPECT_EQ(status.success, true);
  EXPECT_EQ(status.rs, 4096);
  Buffer expectBuffer = Layout::newBuffer(4096);
  memset((void*)expectBuffer.raw(), 100, expectBuffer.size());
  EXPECT_EQ(memcmp((void*)expectBuffer.raw(), (void*)buffer.raw(), buffer.size()), 0);




  Layout::freeBuffer(expectBuffer);
  Layout::freeBuffer(buffer);
  file.remove();
}

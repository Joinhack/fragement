#include <gtest/gtest.h>
#include "btree/btree.h"

using namespace ndb;

TEST(btree, node) {
  AIOFile f("/tmp/aiotest");
  EXPECT_TRUE(f.open());
  
  f.close();
  f.remove();
}
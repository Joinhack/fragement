#include <gtest/gtest.h>
#include "btree/btree.h"

using namespace ndb;

TEST(btree, node) {
  AIOFile f("/tmp/aiotest");
  EXPECT_TRUE(f.open());
  Layout layout1(f);
  Comparator *c = new RawComparator<char>();
  BTree tree(layout1, c);
  tree.init();
  Buffer key("1"), value("2");
  tree.put(key, value);
  f.close();
  f.remove();
}
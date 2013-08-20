#include <gtest/gtest.h>
#include "persist/layout.h"

using namespace ndb;

TEST(Layout, readwrite) {
  AIOFile wf("/tmp/aiotest");
  EXPECT_TRUE(wf.open());
  Layout layout1(wf);
  EXPECT_TRUE(layout1.init(true));

  AIOFile rf("/tmp/aiotest");
  Layout layout2(rf);
  EXPECT_TRUE(rf.open());
  EXPECT_TRUE(layout1.init(false));
  EXPECT_TRUE(memcmp((void*)layout1.getSuperBlock(), (void*)layout2.getSuperBlock(), sizeof(SuperBlock)) == 0);
  wf.close();
  rf.close();
  wf.remove();
}
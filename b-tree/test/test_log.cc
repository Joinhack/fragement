#include <gtest/gtest.h>
#include <string.h>
#include "util/log.h"


TEST(log, test) {
  LOG_ERROR("error");
  LOG_INFO("%s", "info");
  LOG_DEBUG("%s %d", "debug", 1);
}
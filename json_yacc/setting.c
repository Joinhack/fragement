#include <stdlib.h>
#include "setting.h"

static setting default_setting = {
  .malloc = malloc,
  .realloc = realloc,
  .free = free
};

static setting *current_setting = &default_setting;

void set_setting(setting *s) {
  current_setting = s;
}

setting *get_setting() {
  return current_setting;
}

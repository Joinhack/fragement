#include <stdio.h>
#include <string.h>

#include "setting.h"
#include "arraylist.h"

arraylist *arraylist_new() {
  setting *setting = get_setting();
  arraylist *l = setting->malloc(sizeof(arraylist));
  memset(l, 0, sizeof(arraylist));
  return l;
}


void arraylist_free(arraylist *l) {
  setting *setting = get_setting();
  setting->free(l);
}
#include <stdio.h>
#include <string.h>

#include "setting.h"
#include "json.h"
#include "arraylist.h"

arraylist *arraylist_new() {
  setting *setting = get_setting();
  arraylist *l = setting->malloc(sizeof(arraylist));
  memset(l, 0, sizeof(arraylist));
  return l;
}

void arraylist_add(arraylist *l, struct json_object *o) {
  if(l->cap == l->len) {
    setting *setting = get_setting();
    l->cap += 10;
    l->vec = setting->realloc(l->vec, sizeof(struct json_object*) * l->cap);
  }
  l->vec[l->len++] = o;
}

void arraylist_free(arraylist *l) {
  setting *setting = get_setting();
  int i;
  for(i = 0; i < l->len; i++)
    l->vec[i]->free(l->vec[i]);
  if(l->vec != NULL)
    setting->free(l->vec);  
  setting->free(l);

}

void arraylist_move(arraylist *d, arraylist *s) {
  *d = *s;
  s->cap = 0;
  s->len = 0;
  s->vec = NULL;
}
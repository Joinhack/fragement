#ifndef ARRAY_LIST
#define ARRAY_LIST


struct json_object;

typedef struct arraylist {
  struct json_object **vec;
  int len;
  int cap;
} arraylist;

arraylist *arraylist_new();

void arraylist_add(arraylist *l, struct json_object *o);

void arraylist_move(arraylist *d, arraylist *s);

void arraylist_free(arraylist *l);

#endif

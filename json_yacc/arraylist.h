#ifndef ARRAY_LIST
#define ARRAY_LIST


typedef struct arraylist {
  void *data;
  int len;
  int cap;
} arraylist;

arraylist *arraylist_new();
void arraylist_free(arraylist *l);

#endif

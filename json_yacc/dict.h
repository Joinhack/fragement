#ifndef DICT_H
#define DICT_H

typedef struct dict_entry {
  void *key;
  void *value;
  struct dict_entry *bulk_next;
  struct dict_entry *prev;
  struct dict_entry *next;
} dict_entry;

typedef struct dict_opts {
  unsigned int (*hash)(const void *key);
  int (*key_compare)(const void *k1, const void *k2);
  void (*key_free)(void *key);
  void (*value_free)(void *v);
} dict_opts;

typedef struct dict {
  dict_entry **entries;
  dict_opts *opts;
  dict_entry *head;
  dict_entry *tail;
  unsigned int cap;
  unsigned int size;
} dict;

dict *dict_new(dict_opts *opts);

void dict_free(dict *d);

void dict_replace(dict *d, void *k, void *v);

void dict_del(dict *d, void *k);

void dict_rehash(dict *d, unsigned int ns);

dict_entry* dict_find(dict *d, void *k);

unsigned int dict_generic_hash(const char *buf, size_t len);

#define DICT_RESIZE_FACTOR 0.9

#define DICT_KEY_FREE(d, k) if(d->opts->key_free) d->opts->key_free(k)

#define DICT_HASH(d, k) (d->opts->hash(k))

#define DICT_VALUE_FREE(d, v) if(d->opts->value_free) d->opts->value_free(v)

#endif

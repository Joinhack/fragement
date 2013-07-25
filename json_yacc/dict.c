#include <stdlib.h>
#include <string.h>
#include "setting.h"
#include "dict.h"

unsigned int dict_generic_hash(const char *buf, size_t len) {
  unsigned int hash = 5381;

  while (len--)
    hash = ((hash << 5) + hash) + (*buf++); /* hash * 33 + c */
  return hash;
}

dict *dict_new(dict_opts *opts) {
  dict *d = malloc(sizeof(struct dict));
  memset(d, 0, sizeof(struct dict));
  d->opts = opts;
  return d;
}

void dict_rehash(dict *d, unsigned int nsize) {
  setting *s = get_setting();
  dict *nd = dict_new(d->opts);
  dict_entry *entry, *next;
  if(nd->cap > nsize)
    return;
  if(nd->cap == 0 && nsize == 0)
    nsize = 4;
  nd->cap = nsize;
  nd->entries = s->malloc(sizeof(struct dict_entry *) * nd->cap);
  memset(nd->entries, 0, sizeof(struct dict_entry *) * nd->cap);
  entry = d->head;
  while(entry) {
    dict_replace(nd, entry->key, entry->value);
    next = entry->next;
    s->free(entry);
    entry = next;
  }
  if(d->entries)
    s->free(d->entries);
  *d = *nd;
  s->free(nd);
}

static inline dict_entry* _dict_find(dict *d, unsigned int idx, void *k) {
  dict_entry *entry;
  entry = d->entries[idx];
  while(entry) {
    if(d->opts->key_compare(entry->key, k) == 0) {
      return entry;
    }
    entry = entry->bulk_next;
  }
  return NULL;
}

void dict_replace(dict *d, void *k, void *v) {
  unsigned int hash, idx;
  dict_entry *entry;
  setting *s = get_setting();
  if(d->size >= d->cap * DICT_RESIZE_FACTOR) dict_rehash(d, d->cap * 2);
  hash = DICT_HASH(d, k);
  idx = hash % d->cap;
  entry = _dict_find(d, idx, k);
  if(entry) {
    DICT_VALUE_FREE(d, entry->value);
    entry->value = v;
    return;
  }

  entry = s->malloc(sizeof(struct dict_entry));
  memset(entry, 0, sizeof(struct dict_entry));
  entry->bulk_next = d->entries[idx];
  d->entries[idx] = entry;
  entry->key = k;
  entry->value = v;
  if(d->head == NULL) {
    d->tail = d->head = entry;
  } else {
    d->tail->next = entry;
    entry->prev = d->tail;
    d->tail = entry;
  }
  d->size++;
}

dict_entry* dict_find(dict *d, void *k) {
  unsigned int hash, idx;
  hash = DICT_HASH(d, k);
  idx = hash % d->size;
  return _dict_find(d, idx, k);
}

void dict_del(dict *d, void *k) {
  unsigned int hash, idx;
  setting *s = get_setting();
  dict_entry *entry, *prev = NULL;
  hash = DICT_HASH(d, k);
  idx = hash % d->size;
  entry = d->entries[idx];
  while(entry) {
    if(d->opts->key_compare(entry->key, k) == 0) {
      if(prev)
        prev->bulk_next = entry->bulk_next;
      if(entry == d->head && entry == d->tail) {
        d->head = NULL;
        d->tail = NULL;
      } else if(entry == d->head) {
        d->head = entry->next;
      } else if(entry == d->tail) {
        d->tail = entry->prev;
      } else {
        entry->prev->next = entry->next;
        entry->next->prev = entry->prev;
      }
      DICT_VALUE_FREE(d, entry->value);
      DICT_KEY_FREE(d, entry->key);
      s->free(entry);
      d->entries[idx] = NULL;
      break;
    }
    prev = entry;
    entry = entry->bulk_next;
  }
}

void dict_free(dict *d) {
  dict_entry *entry, *next;
  setting *s = get_setting();
  entry = d->head;
  while(entry) {
    DICT_KEY_FREE(d, entry->key);
    DICT_VALUE_FREE(d, entry->value);
    next = entry->next;
    s->free(entry);
    entry = next;
  }
  if(d->entries)
    s->free(d->entries);
  s->free(d);
}

void dict_move(dict *d, dict *s) {
  dict_entry *entry, *next;
  setting *setting = get_setting();
  entry = s->head;
  while(entry) {
    dict_replace(d, entry->key, entry->value);
    next = entry->next;
    setting->free(entry);
    entry = next;
  }

  if(s->entries)
    setting->free(s->entries);
  memset(s, 0, sizeof(struct dict));
}
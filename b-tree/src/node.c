#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "tree.h"
#include "jmalloc.h"

inline static void inner_node_free(node *n) {
  jfree(n);
}

inline static void leaf_node_free(node *n) {
  jfree(n);
}

node *inner_node_new(tree *tr, bid_t b) {
  assert(b < NID_LEAF_START);
  inner_node *n = jmalloc(sizeof(*n));
  memset(n, 0, sizeof(*n));
  n->free = inner_node_free;
  n->tree = tr;
  return (node*)n;
}

node *leaf_node_new(tree *tr, bid_t b) {
  assert(b > NID_LEAF_START);
  inner_node *n = jmalloc(sizeof(*n));
  memset(n, 0, sizeof(*n));
  n->free = inner_node_free;
  n->tree = tr;
  return (node*)n;
}
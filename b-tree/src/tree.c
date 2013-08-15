#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "tree.h"
#include "jmalloc.h"


node* node_new(tree *tr, node_type type) {
  if(type == node_type.INNER_NODE)
    return inner_node_new(++tr->next_inner_id);
  else 
    return leaf_node_new(++tr->next_leaf_id);
}

tree *tree_new() {
  tree * tr = jmalloc(sizeof(struct tree));
  assert(tr);
  memset(tr, 0, sizeof(struct tree));
  tr->next_inner_bid = NID_START;
  tr->next_leaf_bid = NID_LEAF_START;
  return tr;
}

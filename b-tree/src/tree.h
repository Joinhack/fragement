#ifndef BTREE_H
#define BTREE_H

#include "node.h"

typedef struct tree;

struct tree {
  bid_t next_leaf_id;
  bid_t next_inner_id;
  node *node_new(tree *tr, node_type type);
  void (*free)(tree *tree);
};

tree *tree_new();

#endif /**BTREE_H*/

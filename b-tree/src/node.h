#ifndef NODE_H
#define NODE_H

#define NID_NONE            0
#define NID_START           (NID_NIL + 2)
#define NID_LEAF_START      (bid_t)((1LL << 48) + 1)

struct tree;

enum node_type {
  INNER_NODE,
  LEAF_NODE
};

typedef struct node;

struct node {
  int type;
  int dirty;
  bid_t id;
  struct tree *tree;
  void (*free)(node *node);
  void (*maybe_cascade)(node *node);
};

typedef struct inner_node {
  struct node _p;
} inner_node;

typedef struct leaf_node {
  struct node _p;
} leaf_node;



node *inner_node_new(tree *tr, bid_t b);

node *leaf_node_new(tree *tr, bid_t b);

#endif /**end node define */


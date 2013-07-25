#include <stdlib.h>
#include <string.h>
#include "setting.h"
#include "json.h"
#include "json_yy.h"
#include "json_ll.h"


static inline int key_compare(const void *k1, const void *k2) {
  return strcmp((char*)k1, (char*)k2);
}

static inline void _general_free(void *o) {
  setting *setting = get_setting();
  setting->free(o);
}

static inline void _json_free(json_object *o) {
  _general_free((void*)o);
}

static inline void json_value_free(void *v) {
  json_free((json_object*)v);
}

static inline unsigned int json_key_hash(const void *key) {
  return dict_generic_hash(key, strlen(key));
}

dict_opts json_dict_opts = {
  .hash = json_key_hash,
  .key_compare = key_compare,
  .key_free = _general_free,
  .value_free = json_value_free
};

static inline void json_string_free(json_object *o) {
  setting *setting = get_setting();
  if(o->o.str.ptr)
    setting->free(o->o.str.ptr);
  _json_free(o);
}

static inline void json_array_free(json_object *o) {
  if(o->o.array)
    arraylist_free(o->o.array);
  _json_free(o);
}

static inline void json_dict_free(json_object *o) {
  if(o->o.dict)
    dict_free(o->o.dict);
  _json_free(o);
}

json_object *json_new(enum json_type type) {
  setting *setting = get_setting();
  json_object *o = setting->malloc(sizeof(json_object));
  memset(o, 0, sizeof(json_object));
  o->o_type = type;
  switch(type) {
  case json_type_int:
  case json_type_null:
  case json_type_bool:
  case json_type_double:
    o->free = _json_free;
    break;
  case json_type_string:
    o->free = json_string_free;
    break;
  case json_type_array:
    o->o.array = arraylist_new();
    o->free = json_array_free;
    break;
  case json_type_object:
    o->free = json_dict_free;
    break;
  default:
    setting->free(o);
    return NULL;
  }
  return o;
}

void json_free(json_object *o) {
  o->free(o);
}

json_object *json_rs_object;

json_object *json_parse(char *buf, int len) {
  int rs;
  yy_scan_bytes(buf, len);
  rs = yyparse();
  yylex_destroy();
  if(rs != 0) {
    return NULL;
  }
  return json_rs_object;
}




#ifndef JSON_H
#define JSON_H

#include <stdint.h>
#include "setting.h"
#include "arraylist.h"

enum json_type {
  json_type_null,
  json_type_int,
  json_type_bool,
  json_type_double,
  json_type_string,
  json_type_array,
  json_type_object
};

typedef struct json_object {
  enum json_type o_type;
  union data {
    //boolean
    int b;
    //double
    double d;
    //int
    int64_t i;

    //string
    struct {
        char *ptr;
        int len;
    } str;

    //array
    arraylist *array;
  } o;
  void (*free)(struct json_object *obj);
} json_object;

json_object *json_new(enum json_type);

void json_free(json_object *o);

#endif

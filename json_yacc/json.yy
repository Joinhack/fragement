%{

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#define USE_SETTING
#include "json.h"
#include "json_ll.h"
%}

%union {
  char *s;
  int64_t iconst;
  double dconst;
  int bconst;
  json_object *json;
  arraylist *list;
  dict *dict;
}

%token<s>     tok_str_constant
%token<iconst> tok_int_constant
%token<dconst> tok_double_constant
%token<bconst> tok_bool_constant
%token tok_obj_start tok_obj_end tok_colon tok_null tok_quote tok_comma tok_array_start tok_array_end

%type<json> OBJECT
%type<json> MEMBERS
%type<json> PAIR
%type<json> VALUE
%type<json> STRING
%type<json> ARRAY
%type<list> ELEMENTS

%destructor {json_free($$);} VALUE ARRAY STRING
%destructor {arraylist_free($$);} ELEMENTS
%destructor {free($$);} tok_str_constant

%%

JSON: OBJECT {
  json_rs_object =  $1
}
| ARRAY {
  json_rs_object =  $1
}

OBJECT: tok_obj_start tok_obj_end {
  json_object *o = json_new(json_type_object);
  $$ = o;
}
| tok_obj_start MEMBERS tok_obj_end {
}

MEMBERS: PAIR {
}
| PAIR tok_comma MEMBERS {

}

PAIR: STRING tok_colon VALUE {
}

ARRAY: tok_array_start tok_array_end {
  json_object *o = json_new(json_type_array);
  $$ = o;
}
| tok_array_start ELEMENTS tok_array_end {
  json_object *o = json_new(json_type_array);
  arraylist_move(o->o.array, $2);
  arraylist_free($2);
  $$ = o;
}

ELEMENTS: VALUE {
  arraylist *l = arraylist_new();
  arraylist_add(l, $1);
  $$ = l;
}
| VALUE tok_comma ELEMENTS {
  arraylist_add($3, $1);
  $$ = $3;
}

STRING: tok_quote tok_quote {
  json_object *o = json_new(json_type_string);
  $$ = o;
}
|tok_quote tok_str_constant tok_quote {
  json_object *o = json_new(json_type_string);
  o->o.str.ptr = $2;
  o->o.str.len = strlen($2);
  $$ = o;
}

VALUE: STRING {
  $$ = $1;
}
| tok_int_constant {
  json_object *o = json_new(json_type_int);
  o->o.i = $1;
  $$ = o;
} 
| tok_double_constant {
  json_object *o = json_new(json_type_double);
  o->o.d = $1;
  $$ = o;
} 
| tok_bool_constant {
  json_object *o = json_new(json_type_bool);
  o->o.b = $1;
  $$ = o;
}
| tok_null {
  json_object *o = json_new(json_type_null);
  $$ = o;
}
| ARRAY {
  $$ = $1;
}
| OBJECT {
  $$ = $1;
}

;

%%










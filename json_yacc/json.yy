%{

#include <stdint.h>
#include <string.h>
#include "json.h"

%}

%union {
  char *s;
  int64_t iconst;
  double dconst;
  int bconst;
  json_object *json;
}

%token<s>     tok_str_constant
%token<iconst> tok_int_constant
%token<dconst> tok_double_constant
%token<bconst> tok_bool_constant
%token tok_obj_start tok_obj_end tok_colon tok_null tok_quote tok_comma tok_array_start tok_array_end

%type<json> OBJECT
%type<json> MEMBERS
%type<json> PAIR
%type<json> VALUES
%type<json> STRING

%%

JSON: OBJECT {

}
| ARRAY {

}

OBJECT: tok_obj_start tok_obj_end {
  json_object *o = json_new(json_type_object);
  $$ = o;
}
| tok_obj_start MEMBERS tok_obj_end {
  printf("with members\n");
}

MEMBERS: PAIR {
  printf("members\n");
}
| PAIR tok_comma MEMBERS {

}

PAIR: STRING tok_colon VALUES {
}

ARRAY: tok_array_start tok_array_end {

}
| tok_array_start ELEMENTS tok_array_end {

}

ELEMENTS: VALUES {

}
| VALUES tok_comma ELEMENTS {

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

VALUES: STRING {
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
  o->o_type = json_type_bool;
  o->o.b = $1;
  $$ = o;
}
| tok_null {
  json_object *o = json_new(json_type_null);
  $$ = o;
}
| OBJECT {
  $$ = $1;
}

;

%%










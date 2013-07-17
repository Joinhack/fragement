%{

#include <stdint.h>
#include "json.h"

%}

%union {
  char *s;
  int64_t iconst;
  double dconst;
  json_t *json;
}

%token<s>     tok_str_constant
%token<iconst> tok_int_constant
%token<dconst> tok_double_constant
%token tok_obj_start tok_obj_end tok_colon tok_null

%type<json> OBJECT


%%

JSON: OBJECT
;

OBJECT: tok_obj_start tok_obj_end {
  $$ = malloc(sizeof(json_t));
}
;

%%










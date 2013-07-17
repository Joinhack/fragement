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
%token tok_obj_start tok_obj_end tok_colon tok_null tok_quote tok_comma

%type<json> OBJECT
%type<json> MEMBERS
%type<json> PAIR



%%

JSON: OBJECT
;

OBJECT: tok_obj_start tok_obj_end {
  $$ = malloc(sizeof(json_t));
}
| tok_obj_start MEMBERS tok_obj_end {
  printf("with members\n");
}
;

MEMBERS: PAIR {
  printf("members\n");
}
| PAIR MEMBERS {

}
;

PAIR: STRING tok_colon VALUES {

}

STRING: tok_quote tok_quote {

}
|tok_quote tok_str_constant tok_quote {

}

VALUES: STRING {
  printf("value\n");
}
| tok_int_constant {

} 
| tok_double_constant {

} 
| tok_null {

}
| OBJECT {

}
;

%%










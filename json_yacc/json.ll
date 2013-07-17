%{
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-label"

#include <stdio.h>
#include "json.h"
#include "json_yy.h"
void integer_overflow(char* text) {
  yyerror("This integer is too big: \"%s\"\n", text);
  exit(1);
}
%}

%option lex-compat

%option noyywrap

intcosnt           ([+-]?[0-9]+)
hexconst           ("0x"[0-9A-Za-z]+)
dconst             ([+-]?[0-9]*(\.[0-9]+)?([eE][+-]?[0-9]+)?)
whitespace         ([ \t\r\n]*)
unicode            ("\\u"[0-9A-Za-z]{4})
strconst           unicode|([a-zA-Z-][\.a-zA-Z_0-9-]*)|unicode

%%

"false"            { yylval.iconst=0; return tok_int_constant; }
"true"             { yylval.iconst=1; return tok_int_constant; }
"null"             { return tok_null; }
{whitespace}       { /* do nothing */                 }

{intcosnt} {
  errno = 0;
  yylval.iconst = strtoll(yytext+2, NULL, 10);
  if (errno == ERANGE) {
    integer_overflow(yytext);
  }
  return tok_int_constant;
}

{hexconst} {
  errno = 0;
  yylval.iconst = strtoll(yytext+2, NULL, 16);
  if (errno == ERANGE) {
    integer_overflow(yytext);
  }
  return tok_int_constant;
}

{dconst} {
  yylval.dconst = atof(yytext);
  return tok_double_constant;
}

{strconst} {
  yylval.s = strdup(yytext);
  return tok_str_constant;
}

"{" {
  return tok_obj_start;
}

"}" {
  return tok_obj_end;
}

":" {
  return tok_colon;
}

%%


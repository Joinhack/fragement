%{
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-label"

#define USE_SETTING

#include <stdio.h>
#include "setting.h"
#include "json.h"
#include "json_yy.h"

#define yyerror(fmt, ...) fprintf(stderr, fmt, __VA_ARGS__)

//#define YY_INPUT(buf,result,max_size) input_from_buf(buf, &result, max_size)



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
quoteconst         ([\"])

%%

"false"            { yylval.bconst=0; return tok_bool_constant; }
"true"             { yylval.bconst=1; return tok_bool_constant; }
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

"[" {
  return tok_array_start;
}

"]" {
  return tok_array_end;
}

"," {
  return tok_comma;
}

{quoteconst} {
  return tok_quote;
}

":" {
  return tok_colon;
}


%%


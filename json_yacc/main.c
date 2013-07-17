#include <stdio.h>
#include "json.h"
#include "json_yy.h"

int main(int argc, char *argv[]) {
  yyparse();
  return 0;
}
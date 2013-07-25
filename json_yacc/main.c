#include <stdio.h>
#include <time.h>
#include <string.h>
#include <sys/time.h>
#include "json.h"




int main(int argc, char *argv[]) {
  int i;
  char *p ="{nulla:[],a:2, m:[]}";
  
  long start = (long)clock();
  
  for(i = 0; i < 1000000; i++) {
    json_object *j = json_parse(p, strlen(p));
    if(j)
      json_free(j);
  }
  
  long end = (long)clock();
  printf("clock delta: %ld\n", end - start);
  return 0;
}
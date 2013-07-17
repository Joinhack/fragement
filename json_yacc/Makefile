CC=gcc
YACC=bison
LEX=flex
LIBS=-ly
CFLAGS="-Wall"


YY_PREFIX=json_yy
LL_PREFIX=json_ll
objs=${YY_PREFIX}.o ${LL_PREFIX}.o main.o

all:json
	
json:${objs}
	$(CC) $(LIBS) -o $@  $?

${LL_PREFIX}.c:json.ll
	$(LEX) -o $@ $?

${YY_PREFIX}.c:json.yy
	$(YACC) -d -o $@ $?

clean:
	rm -rf *.o json
	rm -rf ${YY_PREFIX}.c ${YY_PREFIX}.h ${LL_PREFIX}.c


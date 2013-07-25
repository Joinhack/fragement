CC=gcc
YACC=bison
LEX=flex
LIBS=
CFLAGS="-Wall" -g


YY_PREFIX=json_yy
LL_PREFIX=json_ll
objs= ${YY_PREFIX}.o ${LL_PREFIX}.o dict.o setting.o arraylist.o json.o main.o

all:json
	
json:${objs}
	$(CC) $(LIBS) -o $@  $?

${LL_PREFIX}.c:json.ll
	$(LEX) --header-file=${LL_PREFIX}.h -o $@ $?

${YY_PREFIX}.c:json.yy
	$(YACC) -d -o $@ $?

clean:
	rm -rf *.o json
	rm -rf ${YY_PREFIX}.c ${YY_PREFIX}.h ${LL_PREFIX}.c


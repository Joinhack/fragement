CC=gcc
YACC=bison
LEX=flex
LIBS=
CFLAGS="-Wall" -O3


YY_PREFIX=json_yy
LL_PREFIX=json_ll
objs= ${LL_PREFIX}.o ${YY_PREFIX}.o dict.o setting.o arraylist.o json.o main.o

all:json

${LL_PREFIX}.c:json.ll
	$(LEX) --header-file=${LL_PREFIX}.h -o $@ $?
	$(YACC) -d -o ${YY_PREFIX}.c json.yy

${YY_PREFIX}.c:json.yy
	$(YACC) -d -o $@ $?

json:${objs}
	$(CC) $(LIBS) -o $@  $?

clean:
	rm -rf *.o json
	rm -rf ${YY_PREFIX}.c ${YY_PREFIX}.h ${LL_PREFIX}.c ${LL_PREFIX}.h


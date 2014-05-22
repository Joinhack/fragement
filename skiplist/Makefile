CC=gcc
CFLAGS=-g
SOURCES=skiplist.c
OBJECTS=$(SOURCES:.c=.o)
EXECUEABLE=skiplist


all: $(EXECUEABLE)


$(EXECUEABLE): $(OBJECTS)
	$(CC) -o $(EXECUEABLE) $^

clean:
	rm -rf $(EXECUEABLE) *.o
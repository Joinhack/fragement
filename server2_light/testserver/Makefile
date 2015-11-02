SO = libtest
CC = g++

OUTPUTDIR = .
OUTPUTFILE = $(OUTPUTDIR)/$(SO).so

CFLAGS=$(dynamic_lib) -fPIC -shared -DTIXML_USE_STL 
include_dirs = -I/usr/include -I/usr/local/lib/ -I/usr/lib/
static_lib=-L/usr/local/lib/
dynamic_lib=-L/usr/lib/ -ltinyxml
objects = $(addsuffix .o, $(basename  $(wildcard *.cpp)))

all:$(objects) 
	$(CC) $(filter-out main.cpp, $(wildcard *.cpp)) $(CFLAGS)  -o $(OUTPUTFILE)

$(objects):%.o:%.cpp
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	-rm *.o


#ifndef __JMALLOC_H
#define __JMALLOC_H


void *jmalloc(size_t s);
void *jrealloc(void *ptr, size_t s);
void jfree(void *ptr);

#endif /*end define __JMALLOC_H**/
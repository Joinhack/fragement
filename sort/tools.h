#ifndef TOOLS_H
#define TOOLS_H

__inline__ void dump(int *array, size_t len) {
	size_t i;
	for(i = 0; i < len; i++)
		printf("%d ", array[i]);
	printf("\n");
}

#endif

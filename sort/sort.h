#ifndef SORT_H
#define SORT_H

#define DUMP(array, len)  \
for(int i = 0; i < len; i++) \
	printf("%d ", array[i]); \
printf("\n");

void insertSort(int*, size_t);
void bubbleSort(int*, size_t);
void quickSort(int*, size_t);

#endif

#include <stdio.h>
#include <string.h>
#include "sort.h"

int main() {
	int array[] = {9,8,2,10,40,20,31,50,100,500,32,34,5,7,3,65,1,2};
	size_t idx;
	size_t arrayLen = sizeof(array)/sizeof(int);
	int copyArray[arrayLen];
	printf("bubble sort:\n");
	memcpy((void*)copyArray, (void*)array, sizeof(array));
	bubbleSort(copyArray, arrayLen);
	DUMP(copyArray, arrayLen);
	
	printf("insert sort:\n");
	memcpy((void*)copyArray, (void*)array, sizeof(array));
	insertSort(copyArray, arrayLen);
	DUMP(copyArray, arrayLen);

	printf("quick sort:\n");
	memcpy((void*)copyArray, (void*)array, sizeof(array));
	quickSort(copyArray, arrayLen);
	DUMP(copyArray, arrayLen);
	
	return 0;
}
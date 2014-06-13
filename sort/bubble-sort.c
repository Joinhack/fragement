#include <stdlib.h>

void bubbleSort(int *array, size_t arrayLen) {
	size_t i,j;
	for(i = 0; i < arrayLen; i++) {
		for(j = i+1; j < arrayLen; j++) {
			if (array[i] > array[j]) {
				int tmp = array[j];
				array[j] = array[i];
				array[i] = tmp;
			}
		}
	}	
}

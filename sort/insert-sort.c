#include <stdlib.h>

void insertSort(int *array, size_t arrayLen) {
	size_t idx, i;
	int tmp;
	for(idx = 1; idx < arrayLen; idx++) {
		i = idx - 1;
		tmp = array[idx];
		while(i >= 0 && array[i] > tmp) {
			array[i+1] = array[i];
			i--;
		}
		array[i+1] = tmp;
	}
}


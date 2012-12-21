#include <stdio.h>


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


int main() {
	int array[] = {9,8,2,5,7,3,65,2};
	size_t idx;
	size_t arrayLen = sizeof(array)/sizeof(int);
	insertSort(array, arrayLen);
	for(idx = 0; idx < arrayLen; idx++) {
		printf("%d ", array[idx]);
	}
	printf("\n");
	return 0;
}

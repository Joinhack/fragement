#include <stdio.h>


int main() {
	int array[] = {9,8,2,5,7,3,65,2};
	size_t idx, i, arrayLen = sizeof(array)/sizeof(int);
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
	for(idx = 0; idx < arrayLen; idx++) {
		printf("%d ", array[idx]);
	}
	printf("\n");
	return 0;
}

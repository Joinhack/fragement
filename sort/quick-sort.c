#include <stdlib.h>

void quick_sort(int *array, size_t left, size_t right) {
	size_t pivotIdx = (left + right)/2;
	int pivot = array[pivotIdx];
	size_t l = left;
	size_t r = right;
	while(l < r) {
		while(l < pivotIdx && array[l] <= pivot) 
			l++;
		if(l < pivotIdx) {
			array[pivotIdx] = array[l];
			pivotIdx = l;
		}
		while(r > pivotIdx && array[r] >= pivot) 
			r--;
		if(r > pivotIdx) {
			array[pivotIdx] = array[r];
			pivotIdx = r;
		}
	}
	array[pivotIdx] = pivot;
	if (pivotIdx - left > 1)
		quick_sort(array, left, pivotIdx - 1);
	if (right - pivotIdx > 1)
		quick_sort(array, pivotIdx + 1, right);
}

void quickSort(int *array, size_t arrayLen) {
	quick_sort(array, 0, arrayLen - 1);		
}

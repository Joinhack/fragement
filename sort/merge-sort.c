#include <stdlib.h>
#include <string.h>

void _merge(int *arr1, int arr1Len, int *arr2, int arr2Len) {
	size_t len = sizeof(int)*arr1Len + arr2Len;
	int *arr = (int*)malloc(len);
	int i = 0, j = 0, idx = 0;
	while(i < arr1Len && j < arr2Len) {
		arr[idx++] = arr1[i] < arr2[j]?arr1[i++]:arr2[j++];
	}
	while(i < arr1Len) {
		arr[idx++] = arr1[i++];	
	}
	while(j < arr2Len) {
		arr[idx++] = arr2[j++];	
	}
	memcpy(arr1, arr, len);
	free(arr);
}

void mergeSort(int *array, size_t arrayLen) {
	int *arr1, *arr2;
	size_t arr1Len, arr2Len;
	arr1Len = arr1Len/2;
	arr2Len = arrayLen - arr1Len;
	arr1 = array;
	arr2 = array + arr1Len;
	mergeSort(arr1, arr1Len);
	mergeSort(arr2, arr2Len);
	_merge(arr1, arr1Len, arr2, arr2Len);
}
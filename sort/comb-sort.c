#include <stdlib.h>

void combSort(int *array, size_t arrayLen) {
	float shrink_factor = 1.3;
  int gap = arrayLen, swapped = 1, swap, i;
 
  while ((gap > 1) || swapped) {
    if (gap > 1) gap = gap / shrink_factor;
 
    swapped = 0; 
    i = 0;
 
    while ((gap + i) < arrayLen) {
      if (array[i] - array[i + gap] > 0) {
        swap = array[i];
        array[i] = array[i + gap];
        array[i + gap] = swap;
        swapped = 1;
      }
      i++;
    }
  }
}

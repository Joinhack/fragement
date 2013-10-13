package util

// find the low bound.
//[1,2,3,4] find 3 will return 3
func Search(max int, f func(mid int) int) int {
	min := 0
	for max >= min {
		mid := (max + min) / 2
		if rs := f(mid); rs > 0 {
			min = mid + 1
		} else if rs < 0 {
			max = mid - 1
		} else {
			min = mid
			if min <= max {
				min += 1
			}
			break
		}
	}
	return min
}

package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"runtime"
	"unsafe"
)

type Mem struct {
	ptr unsafe.Pointer
	i   int
}

func (m *Mem) init(s int) {
	m.ptr = C.malloc(C.size_t(s))
	println("alloc size:", s, m.ptr)
	runtime.SetFinalizer(m, func(m *Mem) {
		C.free(m.ptr)
		println("free :", m.ptr)
	})
}

func main() {
	for i := 0; i < 1000; i++ {
		var m Mem
		m.i++
		m.init(1)
	}
	runtime.GC()
}

//go:build cgo && rustffi

package hotpath

/*
#cgo CFLAGS: -I../../../rust/securemesh_hotpath/include
#cgo LDFLAGS: -L../../../rust/securemesh_hotpath/target/release -lsecuremesh_hotpath
#include "securemesh_hotpath.h"
*/
import "C"
import "unsafe"

func ConstantTimeEqualFFI(left []byte, right []byte) bool {
	if len(left) != len(right) {
		return false
	}
	if len(left) == 0 {
		return true
	}
	result := C.securemesh_constant_time_eq(
		(*C.uint8_t)(unsafe.Pointer(&left[0])),
		(*C.uint8_t)(unsafe.Pointer(&right[0])),
		C.size_t(len(left)),
	)
	return result == 1
}

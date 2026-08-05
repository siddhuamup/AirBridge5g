package hotpath

import "crypto/subtle"

func ConstantTimeEqual(left []byte, right []byte) bool {
	if len(left) != len(right) {
		return false
	}
	return subtle.ConstantTimeCompare(left, right) == 1
}

func IncrementNonce(nonce []byte) {
	for i := len(nonce) - 1; i >= 0; i-- {
		nonce[i]++
		if nonce[i] != 0 {
			return
		}
	}
}

package security

import (
	"fmt"

	"golang.org/x/crypto/curve25519"
)

const X25519KeySize = 32

func X25519(privateKey []byte, publicKey []byte) ([]byte, error) {
	if len(privateKey) != X25519KeySize {
		return nil, fmt.Errorf("private key must be %d bytes", X25519KeySize)
	}
	if len(publicKey) != X25519KeySize {
		return nil, fmt.Errorf("public key must be %d bytes", X25519KeySize)
	}
	return curve25519.X25519(privateKey, publicKey)
}

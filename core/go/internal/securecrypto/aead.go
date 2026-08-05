package securecrypto

import (
	"crypto/aes"
	"crypto/cipher"
	"fmt"

	"github.com/example/securemesh/core/internal/protocol"
	"golang.org/x/crypto/chacha20poly1305"
)

const KeySize256 = 32

func NewAEAD(suite protocol.AEADSuite, key []byte) (cipher.AEAD, error) {
	if len(key) != KeySize256 {
		return nil, fmt.Errorf("%s requires a 32-byte key", suite)
	}

	switch suite {
	case protocol.AEADAES256GCM:
		block, err := aes.NewCipher(key)
		if err != nil {
			return nil, err
		}
		return cipher.NewGCM(block)
	case protocol.AEADChaCha20Poly1305:
		return chacha20poly1305.New(key)
	default:
		return nil, fmt.Errorf("unsupported AEAD suite %q", suite)
	}
}

func Seal(aead cipher.AEAD, nonce []byte, plaintext []byte, aad []byte) []byte {
	return aead.Seal(nil, nonce, plaintext, aad)
}

func Open(aead cipher.AEAD, nonce []byte, ciphertext []byte, aad []byte) ([]byte, error) {
	return aead.Open(nil, nonce, ciphertext, aad)
}

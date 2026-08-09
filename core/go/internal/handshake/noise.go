package handshake

import (
	"crypto/rand"
	"fmt"

	"github.com/flynn/noise"
)

type NoisePattern string
type AEADSuite string

const (
	NoiseIK NoisePattern = "IK"
	NoiseXX NoisePattern = "XX"

	AEADAES256GCM  AEADSuite = "AES256-GCM"
	AEADChaChaPoly AEADSuite = "ChaCha20-Poly1305"
)

type Config struct {
	Initiator     bool
	Pattern       NoisePattern
	AEAD          AEADSuite
	StaticKeypair noise.DHKey
	PeerStatic    []byte
	Prologue      []byte
}

func GenerateStaticKeypair() (noise.DHKey, error) {
	return noise.DH25519.GenerateKeypair(rand.Reader)
}

func RecommendedPattern(peerStaticKnown bool) NoisePattern {
	if peerStaticKnown {
		return NoiseIK
	}
	return NoiseXX
}

func NewState(cfg Config) (*noise.HandshakeState, error) {
	noisePattern, err := pattern(cfg.Pattern)
	if err != nil {
		return nil, err
	}

	return noise.NewHandshakeState(noise.Config{
		CipherSuite:   cipherSuite(cfg.AEAD),
		Random:        rand.Reader,
		Pattern:       noisePattern,
		Initiator:     cfg.Initiator,
		StaticKeypair: cfg.StaticKeypair,
		PeerStatic:    cfg.PeerStatic,
		Prologue:      cfg.Prologue,
	})
}

func cipherSuite(aead AEADSuite) noise.CipherSuite {
	switch aead {
	case AEADAES256GCM:
		return noise.NewCipherSuite(noise.DH25519, noise.CipherAESGCM, noise.HashBLAKE2s)
	default:
		return noise.NewCipherSuite(noise.DH25519, noise.CipherChaChaPoly, noise.HashBLAKE2s)
	}
}

func pattern(value NoisePattern) (noise.HandshakePattern, error) {
	switch value {
	case NoiseIK:
		return noise.HandshakeIK, nil
	case NoiseXX:
		return noise.HandshakeXX, nil
	default:
		return noise.HandshakePattern{}, fmt.Errorf("unsupported Noise pattern %q", value)
	}
}

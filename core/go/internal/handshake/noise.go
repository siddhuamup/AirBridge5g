package handshake

import (
	"crypto/rand"
	"fmt"

	"github.com/example/securemesh/core/internal/protocol"
	"github.com/flynn/noise"
)

type Config struct {
	Initiator     bool
	Pattern       protocol.NoisePattern
	AEAD          protocol.AEADSuite
	StaticKeypair noise.DHKey
	PeerStatic    []byte
	Prologue      []byte
}

func GenerateStaticKeypair() (noise.DHKey, error) {
	return noise.DH25519.GenerateKeypair(rand.Reader)
}

func RecommendedPattern(peerStaticKnown bool) protocol.NoisePattern {
	if peerStaticKnown {
		return protocol.NoiseIK
	}
	return protocol.NoiseXX
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

func cipherSuite(aead protocol.AEADSuite) noise.CipherSuite {
	switch aead {
	case protocol.AEADAES256GCM:
		return noise.NewCipherSuite(noise.DH25519, noise.CipherAESGCM, noise.HashBLAKE2s)
	default:
		return noise.NewCipherSuite(noise.DH25519, noise.CipherChaChaPoly, noise.HashBLAKE2s)
	}
}

func pattern(value protocol.NoisePattern) (noise.HandshakePattern, error) {
	switch value {
	case protocol.NoiseIK:
		return noise.HandshakeIK, nil
	case protocol.NoiseXX:
		return noise.HandshakeXX, nil
	default:
		return noise.HandshakePattern{}, fmt.Errorf("unsupported Noise pattern %q", value)
	}
}

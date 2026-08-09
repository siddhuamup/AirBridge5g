package protocol

import (
	"testing"
)

func TestNegotiateCapabilities(t *testing.T) {
	server := Capabilities{
		AEADSuites:      []AEADSuite{AEADChaCha20Poly1305, AEADAES256GCM},
		Transports:      []Transport{TransportQUIC, TransportSOCKS5TLS},
		HandshakeModes:  []NoisePattern{NoiseIK, NoiseXX},
		ProtocolVersion: "securemesh/1",
	}

	client := Capabilities{
		AEADSuites:      []AEADSuite{AEADChaCha20Poly1305},
		Transports:      []Transport{TransportQUIC},
		HandshakeModes:  []NoisePattern{NoiseXX},
		ProtocolVersion: "securemesh/1",
	}

	profile, err := NegotiateCapabilities(server, client)
	if err != nil {
		t.Fatalf("NegotiateCapabilities failed: %v", err)
	}

	if profile.AEAD != AEADChaCha20Poly1305 {
		t.Errorf("expected ChaCha20Poly1305, got %v", profile.AEAD)
	}
	if profile.Transport != TransportQUIC {
		t.Errorf("expected TransportQUIC, got %v", profile.Transport)
	}
	if profile.NoisePattern != NoiseXX {
		t.Errorf("expected NoiseXX, got %v", profile.NoisePattern)
	}
}

func TestNegotiateCapabilitiesMismatch(t *testing.T) {
	server := Capabilities{
		AEADSuites:      []AEADSuite{AEADAES256GCM},
		ProtocolVersion: "securemesh/1",
	}

	client := Capabilities{
		AEADSuites:      []AEADSuite{AEADChaCha20Poly1305},
		ProtocolVersion: "securemesh/1",
	}

	_, err := NegotiateCapabilities(server, client)
	if err == nil {
		t.Error("expected error for mismatched AEAD suites, got nil")
	}
}

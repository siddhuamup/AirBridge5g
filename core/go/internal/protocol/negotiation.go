package protocol

import "fmt"

type AEADSuite string

const (
	AEADAES256GCM        AEADSuite = "AES-256-GCM"
	AEADChaCha20Poly1305 AEADSuite = "ChaCha20-Poly1305"
)

type Transport string

const (
	TransportQUIC      Transport = "QUIC"
	TransportSOCKS5TLS Transport = "SOCKS5-TLS"
)

type NoisePattern string

const (
	NoiseIK NoisePattern = "Noise_IK"
	NoiseXX NoisePattern = "Noise_XX"
)

type Capabilities struct {
	AEADSuites      []AEADSuite
	Transports      []Transport
	HandshakeModes  []NoisePattern
	ProtocolVersion string
}

type SessionProfile struct {
	AEAD            AEADSuite
	Transport       Transport
	NoisePattern    NoisePattern
	ProtocolVersion string
}

func DefaultCapabilities() Capabilities {
	return Capabilities{
		AEADSuites: []AEADSuite{
			AEADChaCha20Poly1305,
			AEADAES256GCM,
		},
		Transports: []Transport{
			TransportQUIC,
			TransportSOCKS5TLS,
		},
		HandshakeModes: []NoisePattern{
			NoiseIK,
			NoiseXX,
		},
		ProtocolVersion: "securemesh/1",
	}
}

func NegotiateCapabilities(local Capabilities, remote Capabilities) (SessionProfile, error) {
	if local.ProtocolVersion != remote.ProtocolVersion {
		return SessionProfile{}, fmt.Errorf("protocol mismatch: local %q remote %q", local.ProtocolVersion, remote.ProtocolVersion)
	}

	aead, err := NegotiateAEAD(local.AEADSuites, remote.AEADSuites)
	if err != nil {
		return SessionProfile{}, err
	}

	transport, err := negotiateTransport(local.Transports, remote.Transports)
	if err != nil {
		return SessionProfile{}, err
	}

	pattern, err := negotiateNoisePattern(local.HandshakeModes, remote.HandshakeModes)
	if err != nil {
		return SessionProfile{}, err
	}

	return SessionProfile{
		AEAD:            aead,
		Transport:       transport,
		NoisePattern:    pattern,
		ProtocolVersion: local.ProtocolVersion,
	}, nil
}

func NegotiateAEAD(local []AEADSuite, remote []AEADSuite) (AEADSuite, error) {
	remoteSet := make(map[AEADSuite]struct{}, len(remote))
	for _, suite := range remote {
		remoteSet[suite] = struct{}{}
	}

	for _, suite := range local {
		if _, ok := remoteSet[suite]; ok {
			return suite, nil
		}
	}

	return "", fmt.Errorf("no mutually supported AEAD suite")
}

func negotiateTransport(local []Transport, remote []Transport) (Transport, error) {
	remoteSet := make(map[Transport]struct{}, len(remote))
	for _, transport := range remote {
		remoteSet[transport] = struct{}{}
	}

	for _, transport := range local {
		if _, ok := remoteSet[transport]; ok {
			return transport, nil
		}
	}

	return "", fmt.Errorf("no mutually supported transport")
}

func negotiateNoisePattern(local []NoisePattern, remote []NoisePattern) (NoisePattern, error) {
	remoteSet := make(map[NoisePattern]struct{}, len(remote))
	for _, pattern := range remote {
		remoteSet[pattern] = struct{}{}
	}

	for _, pattern := range local {
		if _, ok := remoteSet[pattern]; ok {
			return pattern, nil
		}
	}

	return "", fmt.Errorf("no mutually supported Noise pattern")
}

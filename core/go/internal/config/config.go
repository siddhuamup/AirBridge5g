package config

import (
	"os"
	"strconv"
	"strings"

	"github.com/example/securemesh/core/internal/observability"
	"github.com/example/securemesh/core/internal/protocol"
	"github.com/example/securemesh/core/internal/storage"
)

type Config struct {
	NodeID         string
	AEADPreference []protocol.AEADSuite
	Storage        storage.Config
	Tracing        observability.Config
}

func LoadFromEnv() Config {
	return Config{
		NodeID:         env("SECUREMESH_NODE_ID", "local-dev-node"),
		AEADPreference: parseAEADPreference(env("SECUREMESH_AEAD", "")),
		Storage: storage.Config{
			Driver: env("SECUREMESH_STATE_DRIVER", "sqlite"),
			Path:   env("SECUREMESH_STATE_PATH", "securemesh.db"),
		},
		Tracing: observability.Config{
			ServiceName:  env("SECUREMESH_SERVICE_NAME", "securemesh-node"),
			OTLPEndpoint: env("SECUREMESH_OTEL_ENDPOINT", ""),
			OTLPInsecure: parseBool(env("SECUREMESH_OTEL_INSECURE", "true")),
			SampleRatio:  parseFloat(env("SECUREMESH_TRACE_SAMPLE_RATIO", "1.0")),
		},
	}
}

func env(name string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(name))
	if value == "" {
		return fallback
	}
	return value
}

func parseAEADPreference(raw string) []protocol.AEADSuite {
	if strings.TrimSpace(raw) == "" {
		return []protocol.AEADSuite{
			protocol.AEADChaCha20Poly1305,
			protocol.AEADAES256GCM,
		}
	}

	parts := strings.Split(raw, ",")
	suites := make([]protocol.AEADSuite, 0, len(parts))
	for _, part := range parts {
		switch strings.ToLower(strings.TrimSpace(part)) {
		case "aes", "aes-gcm", "aes256gcm", "aes-256-gcm":
			suites = append(suites, protocol.AEADAES256GCM)
		case "chacha", "chacha20", "chacha20poly1305", "chacha20-poly1305":
			suites = append(suites, protocol.AEADChaCha20Poly1305)
		}
	}

	if len(suites) == 0 {
		return protocol.DefaultCapabilities().AEADSuites
	}
	return suites
}

func parseBool(raw string) bool {
	value, err := strconv.ParseBool(raw)
	return err == nil && value
}

func parseFloat(raw string) float64 {
	value, err := strconv.ParseFloat(raw, 64)
	if err != nil {
		return 1
	}
	return value
}

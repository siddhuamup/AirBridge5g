package config

import (
	"os"
	"testing"
)

func TestLoadFromEnvDefaults(t *testing.T) {
	os.Unsetenv("SECUREMESH_NODE_ID")

	cfg := LoadFromEnv()

	if cfg.NodeID == "" {
		t.Error("expected non-empty default NodeID")
	}
	if cfg.Storage.Driver == "" {
		t.Error("expected non-empty default Storage.Driver")
	}
}

func TestLoadFromEnvCustom(t *testing.T) {
	t.Setenv("SECUREMESH_NODE_ID", "test-node-123")
	t.Setenv("SECUREMESH_STATE_DRIVER", "memory")

	cfg := LoadFromEnv()

	if cfg.NodeID != "test-node-123" {
		t.Errorf("expected NodeID 'test-node-123', got '%s'", cfg.NodeID)
	}
	if cfg.Storage.Driver != "memory" {
		t.Errorf("expected Storage.Driver 'memory', got '%s'", cfg.Storage.Driver)
	}
}

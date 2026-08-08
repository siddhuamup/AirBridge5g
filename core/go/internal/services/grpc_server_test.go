package services

import (
	"context"
	"testing"
	"time"

	controlv1 "github.com/example/securemesh/core/proto/control/v1"
)

func TestGRPCServer_GetStatus(t *testing.T) {
	cfg := DefaultDaemonConfig()
	daemon := NewDaemon(cfg, nil, nil, nil, nil, nil, nil, nil)

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	if err := daemon.Start(ctx); err != nil {
		t.Fatalf("failed to start daemon: %v", err)
	}
	defer func() {
		stopCtx, stopCancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer stopCancel()
		_ = daemon.Stop(stopCtx)
	}()

	server := NewGRPCServer(daemon, "127.0.0.1:0")

	res, err := server.GetStatus(ctx, &controlv1.GetStatusRequest{})
	if err != nil {
		t.Fatalf("GetStatus error: %v", err)
	}

	if res.NodeId != cfg.NodeID {
		t.Errorf("expected NodeId %q, got %q", cfg.NodeID, res.NodeId)
	}
	if res.TunnelState != controlv1.TunnelState_TUNNEL_STATE_STOPPED {
		t.Errorf("expected TunnelState_TUNNEL_STATE_STOPPED, got %v", res.TunnelState)
	}
}

func TestGRPCServer_SetAndGetRole(t *testing.T) {
	cfg := DefaultDaemonConfig()
	daemon := NewDaemon(cfg, nil, nil, nil, nil, nil, nil, nil)
	server := NewGRPCServer(daemon, "127.0.0.1:0")

	ctx := context.Background()

	// Set role to Master
	setRes, err := server.SetRole(ctx, &controlv1.SetRoleRequest{
		Role: controlv1.NodeRole_NODE_ROLE_MASTER,
	})
	if err != nil {
		t.Fatalf("SetRole error: %v", err)
	}
	if setRes.Role != controlv1.NodeRole_NODE_ROLE_MASTER {
		t.Errorf("expected NODE_ROLE_MASTER, got %v", setRes.Role)
	}

	// Get role
	getRes, err := server.GetRole(ctx, &controlv1.GetRoleRequest{})
	if err != nil {
		t.Fatalf("GetRole error: %v", err)
	}
	if getRes.Role != controlv1.NodeRole_NODE_ROLE_MASTER {
		t.Errorf("expected NODE_ROLE_MASTER, got %v", getRes.Role)
	}
}

func TestGRPCServer_GenerateAndImportQR(t *testing.T) {
	cfg := DefaultDaemonConfig()
	daemon := NewDaemon(cfg, nil, nil, nil, nil, nil, nil, nil)
	server := NewGRPCServer(daemon, "127.0.0.1:0")

	ctx := context.Background()

	// Generate QR
	genRes, err := server.GenerateQRCredentials(ctx, &controlv1.GenerateQRRequest{})
	if err != nil {
		t.Fatalf("GenerateQRCredentials error: %v", err)
	}
	if genRes.QrPayload == "" {
		t.Fatal("expected non-empty QrPayload")
	}

	// Import QR
	impRes, err := server.ImportQRCredentials(ctx, &controlv1.ImportQRRequest{
		QrPayload: genRes.QrPayload,
	})
	if err != nil {
		t.Fatalf("ImportQRCredentials error: %v", err)
	}
	if !impRes.Success {
		t.Errorf("expected import success true, got false (error: %s)", impRes.ErrorMessage)
	}
}

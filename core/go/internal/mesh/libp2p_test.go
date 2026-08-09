package mesh

import (
	"context"
	"testing"
	"time"
)

func TestLibP2PServiceLifecycle(t *testing.T) {
	svc, err := NewLibP2PService(LibP2PConfig{
		ListenAddrs: []string{"127.0.0.1:0"},
	})
	if err != nil {
		t.Fatalf("NewLibP2PService error: %v", err)
	}

	if svc.NodeID() == "" {
		t.Error("expected non-empty NodeID")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := svc.Start(ctx); err != nil {
		t.Fatalf("svc.Start error: %v", err)
	}

	stats := svc.GetStats()
	if stats.ConnectedPeers < 0 {
		t.Error("invalid connected peers metric")
	}

	if err := svc.Stop(ctx); err != nil {
		t.Fatalf("svc.Stop error: %v", err)
	}
}

func TestPeerDiscoverySubscription(t *testing.T) {
	svc, err := NewLibP2PService(LibP2PConfig{})
	if err != nil {
		t.Fatalf("NewLibP2PService error: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := svc.Start(ctx); err != nil {
		t.Fatalf("svc.Start error: %v", err)
	}
	defer svc.Stop(ctx)

	subCh, err := svc.Subscribe(ctx, "test-topic")
	if err != nil {
		t.Fatalf("svc.Subscribe error: %v", err)
	}

	if subCh == nil {
		t.Fatal("expected non-nil discovery channel")
	}
}

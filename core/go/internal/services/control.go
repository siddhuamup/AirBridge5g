package services

import (
	"context"
	"time"

	"github.com/example/securemesh/core/internal/storage"
)

type TunnelState string

const (
	TunnelStopped  TunnelState = "stopped"
	TunnelStarting TunnelState = "starting"
	TunnelRunning  TunnelState = "running"
	TunnelDegraded TunnelState = "degraded"
)

type NodeStatus struct {
	NodeID        string
	TunnelState   TunnelState
	ConnectedPeer int
	StartedAt     time.Time
}

type ControlPlane interface {
	StartTunnel(ctx context.Context) error
	StopTunnel(ctx context.Context) error
	Status(ctx context.Context) (NodeStatus, error)
	ListPeers(ctx context.Context) ([]storage.Peer, error)
}

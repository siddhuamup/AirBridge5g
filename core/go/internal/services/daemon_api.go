package services

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/example/securemesh/core/internal/mesh"
)

// SetRoleConvenience sets the node role without explicit context requirement.
func (d *Daemon) SetRoleConvenience(role NodeRole) error {
	return d.SetRole(context.Background(), role)
}

// StopConvenience gracefully shuts down the daemon with default timeout context.
func (d *Daemon) StopConvenience() error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return d.Stop(ctx)
}

// ImportQRCredentials decodes and validates a QR payload string.
func (d *Daemon) ImportQRCredentials(payload string) error {
	creds, err := DecodeQRPayload(payload)
	if err != nil {
		return fmt.Errorf("decode QR credentials: %w", err)
	}

	if time.Now().UnixMilli() > creds.ExpiresAt {
		return fmt.Errorf("QR credentials expired at %d", creds.ExpiresAt)
	}

	d.mu.RLock()
	meshSvc := d.meshService
	d.mu.RUnlock()

	if meshSvc != nil {
		peerID := creds.NodeID // or parse from QR
		peerAddr := fmt.Sprintf("%s:%d", creds.ProxyHost, creds.QUICPort) // Assuming QUIC port is mesh port
		peerInfo := mesh.PeerInfo{
			ID:    peerID,
			Addrs: []string{peerAddr},
		}
		if err := meshSvc.Connect(context.Background(), peerInfo); err != nil {
			return fmt.Errorf("mesh connect: %w", err)
		}
	}

	log.Printf("[airbridge-daemon] successfully imported QR credentials and connected to peer %s", creds.NodeID)
	return nil
}

// GetTrafficSnapshot returns the latest traffic snapshot or an empty one if history is empty.
func (d *Daemon) GetTrafficSnapshot() TrafficSnapshot {
	d.historyMu.RLock()
	defer d.historyMu.RUnlock()

	if len(d.trafficHistory) > 0 {
		return d.trafficHistory[len(d.trafficHistory)-1]
	}
	return d.currentTrafficSnapshot()
}



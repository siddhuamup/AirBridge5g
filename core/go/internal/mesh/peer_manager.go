package mesh

import (
	"fmt"
	"log"
	"sync"
	"time"
)

// PeerStatus represents the current state of a peer.
type PeerStatus int

const (
	PeerActive PeerStatus = iota
	PeerBlocked
	PeerKicked
)

// PeerManager handles peer lifecycle: kick, block, unblock, and trust management.
type PeerManager struct {
	blocked    map[string]time.Time // peerID → blocked at
	kicked     map[string]time.Time // peerID → kicked at
	trustLevel map[string]int       // peerID → trust score (0-100)
	mu         sync.RWMutex
	onKick     func(peerID string)
}

// NewPeerManager creates a new peer manager with the given kick callback.
func NewPeerManager(onKick func(peerID string)) *PeerManager {
	return &PeerManager{
		blocked:    make(map[string]time.Time),
		kicked:     make(map[string]time.Time),
		trustLevel: make(map[string]int),
		onKick:     onKick,
	}
}

// KickPeer disconnects a peer and prevents reconnection for the given duration.
func (pm *PeerManager) KickPeer(peerID string, banDuration time.Duration) error {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	pm.kicked[peerID] = time.Now()
	if banDuration > 0 {
		pm.blocked[peerID] = time.Now().Add(banDuration)
	}

	log.Printf("[airbridge-peers] kicked peer %s (ban=%v)", peerID, banDuration)

	if pm.onKick != nil {
		go pm.onKick(peerID)
	}

	return nil
}

// BlockPeer permanently blocks a peer from connecting.
func (pm *PeerManager) BlockPeer(peerID string) error {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	pm.blocked[peerID] = time.Now().Add(100 * 365 * 24 * time.Hour) // ~100 years
	log.Printf("[airbridge-peers] permanently blocked peer %s", peerID)
	return nil
}

// UnblockPeer removes a peer from the blocklist.
func (pm *PeerManager) UnblockPeer(peerID string) error {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	delete(pm.blocked, peerID)
	delete(pm.kicked, peerID)
	log.Printf("[airbridge-peers] unblocked peer %s", peerID)
	return nil
}

// IsBlocked checks if a peer is currently blocked.
func (pm *PeerManager) IsBlocked(peerID string) bool {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	blockedUntil, ok := pm.blocked[peerID]
	if !ok {
		return false
	}
	if time.Now().After(blockedUntil) {
		delete(pm.blocked, peerID)
		return false
	}
	return true
}

// GetPeerStatus returns the current status of a peer.
func (pm *PeerManager) GetPeerStatus(peerID string) PeerStatus {
	if pm.IsBlocked(peerID) {
		return PeerBlocked
	}
	pm.mu.RLock()
	defer pm.mu.RUnlock()
	if _, kicked := pm.kicked[peerID]; kicked {
		return PeerKicked
	}
	return PeerActive
}

// SetTrustLevel sets the trust score for a peer (0-100).
func (pm *PeerManager) SetTrustLevel(peerID string, level int) {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	if level < 0 {
		level = 0
	}
	if level > 100 {
		level = 100
	}
	pm.trustLevel[peerID] = level
}

// GetTrustLevel returns the trust score for a peer.
func (pm *PeerManager) GetTrustLevel(peerID string) int {
	pm.mu.RLock()
	defer pm.mu.RUnlock()
	if level, ok := pm.trustLevel[peerID]; ok {
		return level
	}
	return 50 // Default trust
}

// ListBlockedPeers returns all currently blocked peer IDs.
func (pm *PeerManager) ListBlockedPeers() []string {
	pm.mu.RLock()
	defer pm.mu.RUnlock()
	result := make([]string, 0, len(pm.blocked))
	for id, until := range pm.blocked {
		if time.Now().Before(until) {
			result = append(result, id)
		}
	}
	return result
}

// PeerInfo returns a human-readable summary of a peer.
func (pm *PeerManager) PeerSummary(peerID string) string {
	status := pm.GetPeerStatus(peerID)
	trust := pm.GetTrustLevel(peerID)
	return fmt.Sprintf("peer=%s status=%d trust=%d", peerID, status, trust)
}

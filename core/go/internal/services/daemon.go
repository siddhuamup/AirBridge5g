package services

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/example/securemesh/core/internal/mesh"
	"github.com/example/securemesh/core/internal/privacy"
	"github.com/example/securemesh/core/internal/proxy"
	"github.com/example/securemesh/core/internal/security"
	"github.com/example/securemesh/core/internal/storage"
)

// NodeRole represents the device's role in the AirBridge mesh.
type NodeRole int

const (
	RoleUnspecified NodeRole = iota
	RoleMaster              // Provider: shares internet
	RoleClient              // Receiver: consumes shared internet
)

// String returns the role name.
func (r NodeRole) String() string {
	switch r {
	case RoleMaster:
		return "master"
	case RoleClient:
		return "client"
	default:
		return "unspecified"
	}
}

// QRCredentials contains the data encoded in a QR code for peer pairing.
type QRCredentials struct {
	NodeID        string `json:"node_id"`
	ProxyHost     string `json:"proxy_host"`
	ProxyPort     int    `json:"proxy_port"`
	QUICPort      int    `json:"quic_port"`
	EncryptionKey string `json:"encryption_key"` // Base64-encoded
	ExpiresAt     int64  `json:"expires_at"`     // Unix milliseconds
	AuthToken     string `json:"auth_token"`
}

// TrafficSnapshot represents a point-in-time view of traffic metrics.
type TrafficSnapshot struct {
	BytesIn           int64
	BytesOut          int64
	ThroughputInBPS   float64
	ThroughputOutBPS  float64
	ActiveConnections int64
	TotalConnections  int64
	PacketsProcessed  int64
	Timestamp         time.Time
}

// PrivacyStats aggregates all privacy engine statistics.
type PrivacyStats struct {
	TTL           privacy.TTLStatsSnapshot
	Fragmentation privacy.FragmentStatsSnapshot
	UserAgent     privacy.UAHarmonizeStatsSnapshot
}

// DaemonConfig configures the control plane daemon.
type DaemonConfig struct {
	NodeID       string
	GRPCAddress  string
	ProxyAddress string
	QUICPort     int
	Version      string
}

// DefaultDaemonConfig returns sensible defaults.
func DefaultDaemonConfig() DaemonConfig {
	return DaemonConfig{
		NodeID:       "airbridge-node",
		GRPCAddress:  "127.0.0.1:50051",
		ProxyAddress: "127.0.0.1:1080",
		QUICPort:     4433,
		Version:      "1.0.0",
	}
}

// Daemon implements the AirBridge 5G control plane.
type Daemon struct {
	cfg DaemonConfig

	// Current state
	role        NodeRole
	tunnelState TunnelState
	startedAt   time.Time

	// Sub-systems
	proxyServer    *proxy.Server
	meshService    *mesh.LibP2PService
	ttlNormalizer  *privacy.TTLNormalizer
	fragmenter     *privacy.Fragmenter
	uaHarmonizer   *privacy.UAHarmonizer
	stateStore     storage.StateStore
	killSwitch     *security.KillSwitch

	// Traffic history for UI graphs
	trafficHistory []TrafficSnapshot
	historyMu      sync.RWMutex
	maxHistory     int

	// Lifecycle
	mu     sync.RWMutex
	ctx    context.Context
	cancel context.CancelFunc
}

// NewDaemon creates a new AirBridge control plane daemon.
func NewDaemon(
	cfg DaemonConfig,
	proxyServer *proxy.Server,
	meshService *mesh.LibP2PService,
	ttlNormalizer *privacy.TTLNormalizer,
	fragmenter *privacy.Fragmenter,
	uaHarmonizer *privacy.UAHarmonizer,
	stateStore storage.StateStore,
	killSwitch *security.KillSwitch,
) *Daemon {
	return &Daemon{
		cfg:            cfg,
		role:           RoleUnspecified,
		tunnelState:    TunnelStopped,
		proxyServer:    proxyServer,
		meshService:    meshService,
		ttlNormalizer:  ttlNormalizer,
		fragmenter:     fragmenter,
		uaHarmonizer:   uaHarmonizer,
		stateStore:     stateStore,
		killSwitch:     killSwitch,
		trafficHistory: make([]TrafficSnapshot, 0, 120),
		maxHistory:     120, // 60 seconds at 500ms intervals
	}
}

// Start initializes the daemon and begins serving.
func (d *Daemon) Start(ctx context.Context) error {
	d.mu.Lock()
	d.ctx, d.cancel = context.WithCancel(ctx)
	d.startedAt = time.Now().UTC()
	d.mu.Unlock()

	// Start mesh service
	if d.meshService != nil {
		if err := d.meshService.Start(d.ctx); err != nil {
			return fmt.Errorf("start mesh: %w", err)
		}
	}

	// Start traffic stats collection
	go d.collectTrafficStats()

	log.Printf("[airbridge-daemon] started (node=%s, platform=%s)", d.cfg.NodeID, runtime.GOOS)
	return nil
}

// Stop gracefully shuts down all daemon sub-systems.
func (d *Daemon) Stop(ctx context.Context) error {
	d.mu.Lock()
	if d.cancel != nil {
		d.cancel()
	}
	proxy := d.proxyServer
	mesh := d.meshService
	d.mu.Unlock()

	// Stop proxy without holding lock
	if proxy != nil {
		if err := proxy.Shutdown(ctx); err != nil {
			log.Printf("[airbridge-daemon] proxy shutdown: %v", err)
		}
	}

	// Stop mesh without holding lock
	if mesh != nil {
		if err := mesh.Stop(ctx); err != nil {
			log.Printf("[airbridge-daemon] mesh shutdown: %v", err)
		}
	}

	d.mu.Lock()
	d.tunnelState = TunnelStopped
	d.mu.Unlock()

	log.Printf("[airbridge-daemon] stopped")
	return nil
}

// StartedAt returns the daemon start time safely.
func (d *Daemon) StartedAt() time.Time {
	d.mu.RLock()
	defer d.mu.RUnlock()
	return d.startedAt
}

// UpdateDaemonConfig updates the active configuration live at runtime.
func (d *Daemon) UpdateDaemonConfig(newCfg DaemonConfig) {
	d.mu.Lock()
	defer d.mu.Unlock()
	if newCfg.NodeID != "" {
		d.cfg.NodeID = newCfg.NodeID
	}
	if newCfg.ProxyAddress != "" {
		d.cfg.ProxyAddress = newCfg.ProxyAddress
	}
	if newCfg.GRPCAddress != "" {
		d.cfg.GRPCAddress = newCfg.GRPCAddress
	}
	if newCfg.QUICPort > 0 {
		d.cfg.QUICPort = newCfg.QUICPort
	}
	log.Printf("[airbridge-daemon] live config updated (nodeID=%s, proxyAddr=%s, grpcAddr=%s)",
		d.cfg.NodeID, d.cfg.ProxyAddress, d.cfg.GRPCAddress)
}

// TunnelState returns the current tunnel state safely.
func (d *Daemon) TunnelState() TunnelState {
	d.mu.RLock()
	defer d.mu.RUnlock()
	return d.tunnelState
}

// SetRole changes the node's role (Master/Client).
func (d *Daemon) SetRole(ctx context.Context, role NodeRole) error {
	d.mu.Lock()
	defer d.mu.Unlock()

	d.role = role
	log.Printf("[airbridge-daemon] role set to %s", role)
	return nil
}

// GetRole returns the current node role.
func (d *Daemon) GetRole() NodeRole {
	d.mu.RLock()
	defer d.mu.RUnlock()
	return d.role
}

// Status returns the current node status.
func (d *Daemon) Status(ctx context.Context) (NodeStatus, error) {
	d.mu.RLock()
	defer d.mu.RUnlock()

	peerCount := 0
	if d.meshService != nil {
		peerCount = len(d.meshService.ListConnectedPeers())
	}

	return NodeStatus{
		NodeID:        d.cfg.NodeID,
		TunnelState:   d.tunnelState,
		ConnectedPeer: peerCount,
		StartedAt:     d.startedAt,
	}, nil
}

// StartTunnel activates the proxy and transport layers.
func (d *Daemon) StartTunnel(ctx context.Context) error {
	d.mu.Lock()
	defer d.mu.Unlock()

	if d.tunnelState == TunnelRunning {
		return nil
	}

	d.tunnelState = TunnelStarting

	// Start SOCKS5 proxy (master only)
	if d.role == RoleMaster && d.proxyServer != nil {
		bindErrCh := make(chan error, 1)
		go func() {
			if err := d.proxyServer.ListenAndServe(d.ctx); err != nil {
				log.Printf("[airbridge-daemon] proxy server error: %v", err)
				d.mu.Lock()
				d.tunnelState = TunnelDegraded
				d.mu.Unlock()
				select {
				case bindErrCh <- err:
				default:
				}
			}
		}()

		// Wait briefly to check if initial net.Listen failed
		select {
		case err := <-bindErrCh:
			return fmt.Errorf("socks5 bind failed: %w", err)
		case <-time.After(100 * time.Millisecond):
			// Bind succeeded
		}
	}

	// Arm Kill Switch if available
	if d.killSwitch != nil {
		if err := d.killSwitch.Enable(); err != nil {
			log.Printf("[airbridge-daemon] kill switch enable warning: %v", err)
		}
	}

	d.tunnelState = TunnelRunning
	log.Printf("[airbridge-daemon] tunnel started (role=%s)", d.role)
	return nil
}

// StopTunnel deactivates the proxy and transport layers.
func (d *Daemon) StopTunnel(ctx context.Context) error {
	d.mu.Lock()
	defer d.mu.Unlock()

	if d.killSwitch != nil {
		_ = d.killSwitch.Disable()
	}

	if d.proxyServer != nil {
		if err := d.proxyServer.Shutdown(ctx); err != nil {
			log.Printf("[airbridge-daemon] proxy shutdown: %v", err)
		}
	}

	d.tunnelState = TunnelStopped
	log.Printf("[airbridge-daemon] tunnel stopped")
	return nil
}

// ListPeers returns all peers from the mesh and state store.
func (d *Daemon) ListPeers(ctx context.Context) ([]storage.Peer, error) {
	if d.stateStore != nil {
		return d.stateStore.ListPeers(ctx)
	}
	return nil, nil
}

// GenerateQRCredentials creates a QR code payload for peer pairing.
func (d *Daemon) GenerateQRCredentials() (QRCredentials, error) {
	d.mu.RLock()
	defer d.mu.RUnlock()

	// Generate session encryption key
	keyBytes := make([]byte, 32) // 256-bit key
	if _, err := rand.Read(keyBytes); err != nil {
		return QRCredentials{}, fmt.Errorf("generate encryption key: %w", err)
	}

	// Generate auth token
	tokenBytes := make([]byte, 16)
	if _, err := rand.Read(tokenBytes); err != nil {
		return QRCredentials{}, fmt.Errorf("generate auth token: %w", err)
	}

	// Detect local IP for proxy address
	proxyHost := detectLocalIP()

	creds := QRCredentials{
		NodeID:        d.cfg.NodeID,
		ProxyHost:     proxyHost,
		ProxyPort:     extractPort(d.cfg.ProxyAddress),
		QUICPort:      d.cfg.QUICPort,
		EncryptionKey: base64.StdEncoding.EncodeToString(keyBytes),
		ExpiresAt:     time.Now().Add(24 * time.Hour).UnixMilli(),
		AuthToken:     base64.StdEncoding.EncodeToString(tokenBytes),
	}

	return creds, nil
}

// EncodeQRPayload serializes QR credentials to a base64 JSON string.
func EncodeQRPayload(creds QRCredentials) (string, error) {
	data, err := json.Marshal(creds)
	if err != nil {
		return "", fmt.Errorf("marshal QR credentials: %w", err)
	}
	return base64.StdEncoding.EncodeToString(data), nil
}

// DecodeQRPayload deserializes a base64 JSON string to QR credentials.
func DecodeQRPayload(payload string) (QRCredentials, error) {
	data, err := base64.StdEncoding.DecodeString(payload)
	if err != nil {
		return QRCredentials{}, fmt.Errorf("decode QR payload: %w", err)
	}
	var creds QRCredentials
	if err := json.Unmarshal(data, &creds); err != nil {
		return QRCredentials{}, fmt.Errorf("unmarshal QR credentials: %w", err)
	}
	return creds, nil
}

// GetTrafficStats returns current and historical traffic data.
func (d *Daemon) GetTrafficStats() (TrafficSnapshot, []TrafficSnapshot) {
	current := d.currentTrafficSnapshot()

	d.historyMu.RLock()
	history := make([]TrafficSnapshot, len(d.trafficHistory))
	copy(history, d.trafficHistory)
	d.historyMu.RUnlock()

	return current, history
}

// GetPrivacyStats returns aggregated privacy engine statistics.
func (d *Daemon) GetPrivacyStats() PrivacyStats {
	stats := PrivacyStats{}
	if d.ttlNormalizer != nil {
		stats.TTL = d.ttlNormalizer.GetStats()
	}
	if d.fragmenter != nil {
		stats.Fragmentation = d.fragmenter.GetStats()
	}
	if d.uaHarmonizer != nil {
		stats.UserAgent = d.uaHarmonizer.GetStats()
	}
	return stats
}

// collectTrafficStats periodically snapshots traffic metrics.
func (d *Daemon) collectTrafficStats() {
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	var prevIn, prevOut int64
	prevTime := time.Now()

	for {
		select {
		case <-d.ctx.Done():
			return
		case <-ticker.C:
			snapshot := d.currentTrafficSnapshot()
			now := time.Now()
			elapsed := now.Sub(prevTime).Seconds()

			if elapsed <= 0 {
				elapsed = 1.0 // Guard against NTP time sync jumps
			}

			bytesInDiff := snapshot.BytesIn - prevIn
			if bytesInDiff < 0 {
				bytesInDiff = 0
			}
			bytesOutDiff := snapshot.BytesOut - prevOut
			if bytesOutDiff < 0 {
				bytesOutDiff = 0
			}
			snapshot.ThroughputInBPS = float64(bytesInDiff) * 8 / elapsed
			snapshot.ThroughputOutBPS = float64(bytesOutDiff) * 8 / elapsed

			snapshot.Timestamp = now
			prevIn = snapshot.BytesIn
			prevOut = snapshot.BytesOut
			prevTime = now

			d.historyMu.Lock()
			d.trafficHistory = append(d.trafficHistory, snapshot)
			if len(d.trafficHistory) > d.maxHistory {
				d.trafficHistory = d.trafficHistory[len(d.trafficHistory)-d.maxHistory:]
			}
			d.historyMu.Unlock()
		}
	}
}

// currentTrafficSnapshot captures current proxy metrics.
func (d *Daemon) currentTrafficSnapshot() TrafficSnapshot {
	snapshot := TrafficSnapshot{Timestamp: time.Now().UTC()}

	if d.proxyServer != nil {
		metrics := d.proxyServer.GetMetrics()
		snapshot.BytesIn = metrics.BytesIn
		snapshot.BytesOut = metrics.BytesOut
		snapshot.ActiveConnections = metrics.ActiveConnections
		snapshot.TotalConnections = metrics.TotalConnections
	}

	if d.ttlNormalizer != nil {
		ttlStats := d.ttlNormalizer.GetStats()
		snapshot.PacketsProcessed = ttlStats.PacketsProcessed
	}

	return snapshot
}

// detectLocalIP finds the device's local network IP.
func detectLocalIP() string {
	ifaces, err := net.Interfaces()
	if err != nil {
		return "127.0.0.1"
	}

	isVirtual := func(name string) bool {
		nameLower := strings.ToLower(name)
		for _, prefix := range []string{"docker", "vbox", "veth", "wsl", "br-", "tun", "tap", "vnic", "vmnet"} {
			if strings.Contains(nameLower, prefix) {
				return true
			}
		}
		return false
	}

	var fallback string
	for _, iface := range ifaces {
		if (iface.Flags&net.FlagUp) == 0 || (iface.Flags&net.FlagLoopback) != 0 {
			continue
		}
		if isVirtual(iface.Name) {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
				if ip4 := ipNet.IP.To4(); ip4 != nil {
					nameLower := strings.ToLower(iface.Name)
					if strings.Contains(nameLower, "wlan") || strings.Contains(nameLower, "wifi") || strings.Contains(nameLower, "eth") || strings.Contains(nameLower, "en") {
						return ip4.String()
					}
					if fallback == "" {
						fallback = ip4.String()
					}
				}
			}
		}
	}

	if fallback != "" {
		return fallback
	}
	return "127.0.0.1"
}

// extractPort extracts the port number from a host:port string.
func extractPort(address string) int {
	_, portStr, err := net.SplitHostPort(address)
	if err != nil {
		return 1080
	}
	port, err := strconv.Atoi(portStr)
	if err != nil || port <= 0 || port > 65535 {
		return 1080
	}
	return port
}

// PrivacyConfig contains runtime toggle settings for the privacy engine.
type PrivacyConfig struct {
	TTLEnabled         bool `json:"ttl_enabled"`
	FragmenterEnabled  bool `json:"fragmenter_enabled"`
	UAHarmonizeEnabled bool `json:"ua_harmonize_enabled"`
}

// GetPrivacyConfig returns current privacy engine state.
func (d *Daemon) GetPrivacyConfig() PrivacyConfig {
	d.mu.RLock()
	defer d.mu.RUnlock()
	return PrivacyConfig{
		TTLEnabled:         d.ttlNormalizer != nil && d.ttlNormalizer.IsEnabled(),
		FragmenterEnabled:  d.fragmenter != nil && d.fragmenter.IsEnabled(),
		UAHarmonizeEnabled: d.uaHarmonizer != nil && d.uaHarmonizer.IsEnabled(),
	}
}

// SetPrivacyConfig dynamically enables/disables privacy features at runtime.
func (d *Daemon) SetPrivacyConfig(cfg PrivacyConfig) {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.ttlNormalizer != nil {
		d.ttlNormalizer.SetEnabled(cfg.TTLEnabled)
	}
	if d.fragmenter != nil {
		d.fragmenter.SetEnabled(cfg.FragmenterEnabled)
	}
	if d.uaHarmonizer != nil {
		d.uaHarmonizer.SetEnabled(cfg.UAHarmonizeEnabled)
	}
	log.Printf("[airbridge-daemon] privacy config updated: TTL=%v Frag=%v UA=%v",
		cfg.TTLEnabled, cfg.FragmenterEnabled, cfg.UAHarmonizeEnabled)
}

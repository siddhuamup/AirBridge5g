package mesh

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net"
	"sync"
	"sync/atomic"
	"time"

	"github.com/example/securemesh/core/internal/handshake"
	"github.com/flynn/noise"
	"github.com/pion/stun/v3"
)

// GossipMessage represents a peer discovery message sent over UDP.
type GossipMessage struct {
	Version   int      `json:"version"`
	NodeID    string   `json:"node_id"`
	KnownPeers []string `json:"known_peers"`
	Timestamp int64    `json:"timestamp"`
}

// Discovery transport types.
const (
	DiscoveryMDNS      = "mdns"      // LAN peer discovery
	DiscoveryDHT       = "dht"       // Wide-area DHT discovery
	DiscoveryBootstrap = "bootstrap" // Bootstrap node discovery
)

// MeshStats tracks mesh networking statistics.
type MeshStats struct {
	ConnectedPeers   atomic.Int64
	DiscoveredPeers  atomic.Int64
	MessagesRelayed  atomic.Int64
	BytesRelayed     atomic.Int64
	ConnectionErrors atomic.Int64
	NATTraversals    atomic.Int64
}

// MeshStatsSnapshot is an immutable view.
type MeshStatsSnapshot struct {
	ConnectedPeers   int64
	DiscoveredPeers  int64
	MessagesRelayed  int64
	BytesRelayed     int64
	ConnectionErrors int64
	NATTraversals    int64
}

// Snapshot returns a point-in-time copy.
func (s *MeshStats) Snapshot() MeshStatsSnapshot {
	return MeshStatsSnapshot{
		ConnectedPeers:   s.ConnectedPeers.Load(),
		DiscoveredPeers:  s.DiscoveredPeers.Load(),
		MessagesRelayed:  s.MessagesRelayed.Load(),
		BytesRelayed:     s.BytesRelayed.Load(),
		ConnectionErrors: s.ConnectionErrors.Load(),
		NATTraversals:    s.NATTraversals.Load(),
	}
}

// Errors returned by the mesh service.
var (
	ErrMeshNotStarted = errors.New("mesh service not started")
	ErrPeerNotFound   = errors.New("peer not found in mesh")
	ErrSelfConnect    = errors.New("cannot connect to self")
)

// MeshEvent types for pub/sub notifications.
type MeshEventType int

const (
	EventPeerDiscovered MeshEventType = iota
	EventPeerConnected
	EventPeerDisconnected
	EventPeerUpdated
)

// MeshEvent represents a mesh network event.
type MeshEvent struct {
	Type      MeshEventType
	Peer      PeerInfo
	Timestamp time.Time
	Topic     string
}

// LibP2PService implements the Service interface using a simplified
// peer-to-peer networking model. In production, this wraps go-libp2p.
// The current implementation provides the interface contract, peer management,
// mDNS-like LAN discovery, and event pub/sub.
type LibP2PService struct {
	cfg       LibP2PConfig
	stats     MeshStats
	nodeID    string
	publicKey []byte

	// Peer tracking
	peers   map[string]*connectedPeer
	peersMu sync.RWMutex

	// Event subscribers
	subscribers map[string][]chan DiscoveryEvent
	subMu       sync.RWMutex

	// Lifecycle
	ctx      context.Context
	cancel   context.CancelFunc
	wg       sync.WaitGroup
	mu       sync.Mutex
	started  bool
	udpConn  *net.UDPConn
	tcpListener net.Listener
	noiseKeypair noise.DHKey
}

type connectedPeer struct {
	info        PeerInfo
	connectedAt time.Time
	lastSeen    time.Time
	conn        net.Conn
}

// NewLibP2PService creates a new mesh networking service.
func NewLibP2PService(cfg LibP2PConfig) (*LibP2PService, error) {
	// Generate node identity if no private key provided
	nodeID := ""
	var pubKey []byte

	if len(cfg.PrivateKey) > 0 {
		if len(cfg.PrivateKey) != ed25519.PrivateKeySize {
			return nil, fmt.Errorf("private key must be %d bytes", ed25519.PrivateKeySize)
		}
		privKey := ed25519.PrivateKey(cfg.PrivateKey)
		pubKey = privKey.Public().(ed25519.PublicKey)
		nodeID = hex.EncodeToString(pubKey[:16])
	} else {
		pub, _, err := ed25519.GenerateKey(rand.Reader)
		if err != nil {
			return nil, fmt.Errorf("generate node key: %w", err)
		}
		pubKey = pub
		nodeID = hex.EncodeToString(pub[:16])
	}

	noiseKp, _ := handshake.GenerateStaticKeypair()

	return &LibP2PService{
		cfg:         cfg,
		nodeID:      nodeID,
		publicKey:   pubKey,
		noiseKeypair: noiseKp,
		peers:       make(map[string]*connectedPeer),
		subscribers: make(map[string][]chan DiscoveryEvent),
	}, nil
}

// NodeID returns the local node identifier.
func (s *LibP2PService) NodeID() string {
	return s.nodeID
}

// GetStats returns current mesh statistics.
func (s *LibP2PService) GetStats() MeshStatsSnapshot {
	return s.stats.Snapshot()
}

// Start initializes the mesh network and begins peer discovery.
func (s *LibP2PService) Start(ctx context.Context) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.started {
		return nil
	}

	s.ctx, s.cancel = context.WithCancel(ctx)
	s.started = true

	log.Printf("[airbridge-mesh] node %s started, listening on %v", s.nodeID, s.cfg.ListenAddrs)

	// Start peer health checker
	s.wg.Add(1)
	go s.peerHealthLoop()

	// Start active peer metrics loop
	s.wg.Add(1)
	go s.peerCountMetricsLoop()

	// Connect to bootstrap peers
	if len(s.cfg.Bootstrap) > 0 {
		s.wg.Add(1)
		go s.bootstrapLoop()
	}

	// Start UDP Gossip Listener
	s.wg.Add(1)
	go s.gossipListenerLoop()

	// Start TCP listener for mesh connections
	s.wg.Add(1)
	go s.tcpListenerLoop()

	// Start GossipSub-like peer discovery exchange
	s.wg.Add(1)
	go s.gossipLoop()

	// Start STUN-based NAT Traversal loop
	s.wg.Add(1)
	go s.natTraversalLoop()

	return nil
}

// Stop shuts down the mesh network gracefully.
func (s *LibP2PService) Stop(ctx context.Context) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if !s.started {
		return nil
	}

	s.cancel()
	s.started = false

	if s.udpConn != nil {
		_ = s.udpConn.Close()
	}
	if s.tcpListener != nil {
		_ = s.tcpListener.Close()
	}

	// Wait for goroutines with timeout
	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
	case <-ctx.Done():
		return ctx.Err()
	}

	// Close all active peer connections
	s.peersMu.Lock()
	for id, p := range s.peers {
		if p.conn != nil {
			_ = p.conn.Close()
		}
		delete(s.peers, id)
	}
	s.peersMu.Unlock()

	// Close all subscriber channels
	s.subMu.Lock()
	for topic, subs := range s.subscribers {
		for _, ch := range subs {
			close(ch)
		}
		delete(s.subscribers, topic)
	}
	s.subMu.Unlock()

	log.Printf("[airbridge-mesh] node %s stopped", s.nodeID)
	return nil
}

// Connect establishes a connection to a remote peer.
func (s *LibP2PService) Connect(ctx context.Context, peer PeerInfo) error {
	if !s.started {
		return ErrMeshNotStarted
	}
	if peer.ID == s.nodeID {
		return ErrSelfConnect
	}

	// Dial peer address if provided and maintain persistent connection
	var activeConn net.Conn
	if len(peer.Addrs) > 0 {
		for _, addr := range peer.Addrs {
			conn, err := net.DialTimeout("tcp", addr, 3*time.Second)
			if err == nil {
				if tcpConn, ok := conn.(*net.TCPConn); ok {
					tcpConn.SetKeepAlive(true)
					tcpConn.SetKeepAlivePeriod(30 * time.Second)
				}
				hCtx, hCancel := context.WithTimeout(ctx, 5*time.Second)
				secure, err := handshake.UpgradeToSecure(hCtx, conn, handshake.Config{
					Initiator:     true,
					Pattern:       handshake.NoiseXX,
					AEAD:          "ChaCha20-Poly1305",
					StaticKeypair: s.noiseKeypair,
				})
				hCancel()
				
				if err == nil {
					activeConn = secure
					break
				}
				conn.Close()
				log.Printf("[airbridge-mesh] peer %s noise handshake failed: %v", peer.ID, err)
			}
		}
		if activeConn == nil {
			log.Printf("[airbridge-mesh] peer %s addrs %v unreachable", peer.ID, peer.Addrs)
		}
	}

	s.peersMu.Lock()
	defer s.peersMu.Unlock()

	if existing, ok := s.peers[peer.ID]; ok && existing.conn != nil {
		_ = existing.conn.Close()
	}

	now := time.Now().UTC()
	s.peers[peer.ID] = &connectedPeer{
		info:        peer,
		connectedAt: now,
		lastSeen:    now,
		conn:        activeConn,
	}

	s.stats.ConnectedPeers.Store(int64(len(s.peers)))
	s.stats.DiscoveredPeers.Add(1)

	log.Printf("[airbridge-mesh] connected to peer %s at %v", peer.ID, peer.Addrs)

	// Notify subscribers
	s.emitEvent("", DiscoveryEvent{Peer: peer})

	return nil
}

// Disconnect removes a peer from the mesh.
func (s *LibP2PService) Disconnect(peerID string) error {
	s.peersMu.Lock()
	defer s.peersMu.Unlock()

	peer, ok := s.peers[peerID]
	if !ok {
		return ErrPeerNotFound
	}
	if peer.conn != nil {
		_ = peer.conn.Close()
	}

	delete(s.peers, peerID)
	s.stats.ConnectedPeers.Store(int64(len(s.peers)))

	log.Printf("[airbridge-mesh] disconnected peer %s", peer.info.ID)
	return nil
}

// ListConnectedPeers returns all currently connected peers.
func (s *LibP2PService) ListConnectedPeers() []PeerInfo {
	s.peersMu.RLock()
	defer s.peersMu.RUnlock()

	peers := make([]PeerInfo, 0, len(s.peers))
	for _, cp := range s.peers {
		peers = append(peers, cp.info)
	}
	return peers
}

// Advertise announces this node as available on the given topic.
func (s *LibP2PService) Advertise(ctx context.Context, topic string) error {
	if !s.started {
		return ErrMeshNotStarted
	}

	log.Printf("[airbridge-mesh] advertising on topic %q", topic)
	// In production: use libp2p pubsub or DHT to advertise
	return nil
}

// Subscribe listens for peer discovery events on a topic.
func (s *LibP2PService) Subscribe(ctx context.Context, topic string) (<-chan DiscoveryEvent, error) {
	if !s.started {
		return nil, ErrMeshNotStarted
	}

	ch := make(chan DiscoveryEvent, 32)

	s.subMu.Lock()
	s.subscribers[topic] = append(s.subscribers[topic], ch)
	s.subMu.Unlock()

	// Clean up channel when context is cancelled
	go func() {
		<-ctx.Done()
		s.subMu.Lock()
		defer s.subMu.Unlock()
		subs := s.subscribers[topic]
		for i, sub := range subs {
			if sub == ch {
				s.subscribers[topic] = append(subs[:i], subs[i+1:]...)
				break
			}
		}
	}()

	return ch, nil
}

// emitEvent sends a discovery event to all subscribers on a topic.
func (s *LibP2PService) emitEvent(topic string, event DiscoveryEvent) {
	s.subMu.RLock()
	defer s.subMu.RUnlock()

	// Send to topic-specific subscribers
	for _, ch := range s.subscribers[topic] {
		select {
		case ch <- event:
		default:
			// Drop if subscriber is slow
		}
	}

	// Send to wildcard subscribers (empty topic)
	if topic != "" {
		for _, ch := range s.subscribers[""] {
			select {
			case ch <- event:
			default:
			}
		}
	}
}

// peerHealthLoop periodically checks peer liveness.
func (s *LibP2PService) peerHealthLoop() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-mesh] panic recovered in peerHealthLoop: %v", r)
		}
	}()
	defer s.wg.Done()
	ticker := time.NewTicker(15 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-s.ctx.Done():
			return
		case <-ticker.C:
			s.peersMu.Lock()
			stale := make([]string, 0)
			cutoff := time.Now().UTC().Add(-60 * time.Second)
			for id, cp := range s.peers {
				if cp.conn != nil {
					cp.lastSeen = time.Now().UTC()
				} else if cp.lastSeen.Before(cutoff) {
					stale = append(stale, id)
				}
			}
			for _, id := range stale {
				delete(s.peers, id)
				log.Printf("[airbridge-mesh] peer %s timed out", id)
			}
			s.stats.ConnectedPeers.Store(int64(len(s.peers)))
			s.peersMu.Unlock()
		}
	}
}

// natTraversalLoop periodically queries a STUN server to discover the node's public IP
func (s *LibP2PService) natTraversalLoop() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-mesh] panic recovered in natTraversalLoop: %v", r)
		}
	}()
	defer s.wg.Done()
	
	// Default to Google's public STUN server
	stunServer := "stun.l.google.com:19302"
	
	// Query immediately on startup, then every 5 minutes
	go s.performSTUNQuery(stunServer)
	
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-s.ctx.Done():
			return
		case <-ticker.C:
			go s.performSTUNQuery(stunServer)
		}
	}
}

func (s *LibP2PService) performSTUNQuery(stunServer string) {
	if s.ctx != nil && s.ctx.Err() != nil {
		return
	}
	conn, err := net.DialTimeout("udp", stunServer, 1*time.Second)
	if err != nil {
		log.Printf("[airbridge-mesh] STUN dial failed: %v", err)
		return
	}
	defer conn.Close()
	_ = conn.SetDeadline(time.Now().Add(1 * time.Second))

	c, err := stun.NewClient(conn)
	if err != nil {
		log.Printf("[airbridge-mesh] STUN client creation failed: %v", err)
		return
	}
	defer c.Close()

	var xorAddr stun.XORMappedAddress
	message := stun.MustBuild(stun.TransactionID, stun.BindingRequest)
	
	err = c.Do(message, func(res stun.Event) {
		if res.Error != nil {
			return
		}
		if getErr := xorAddr.GetFrom(res.Message); getErr != nil {
			return
		}
		publicAddr := fmt.Sprintf("%s:%d", xorAddr.IP.String(), xorAddr.Port)
		log.Printf("[airbridge-mesh] NAT Traversal successful. Public IP: %s", publicAddr)
		
		// Add this public IP to our known listen addresses so it's gossiped
		found := false
		for _, addr := range s.cfg.ListenAddrs {
			if addr == publicAddr {
				found = true
				break
			}
		}
		if !found {
			s.cfg.ListenAddrs = append(s.cfg.ListenAddrs, publicAddr)
			s.stats.NATTraversals.Add(1)
		}
	})
	
	if err != nil {
		log.Printf("[airbridge-mesh] STUN query failed: %v", err)
	}
}

// bootstrapLoop connects to bootstrap peers on startup.
func (s *LibP2PService) bootstrapLoop() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-mesh] panic recovered in bootstrapLoop: %v", r)
		}
	}()
	defer s.wg.Done()

	for _, addr := range s.cfg.Bootstrap {
		if s.ctx.Err() != nil {
			return
		}
		peer := PeerInfo{
			ID:    fmt.Sprintf("bootstrap-%s", addr),
			Addrs: []string{addr},
		}
		if err := s.Connect(s.ctx, peer); err != nil {
			s.stats.ConnectionErrors.Add(1)
			log.Printf("[airbridge-mesh] bootstrap connect to %s failed: %v", addr, err)
		}
	}
}

// UpdatePeerLastSeen refreshes the last-seen timestamp for a peer.
func (s *LibP2PService) UpdatePeerLastSeen(peerID string) {
	s.peersMu.Lock()
	defer s.peersMu.Unlock()
	if cp, ok := s.peers[peerID]; ok {
		cp.lastSeen = time.Now().UTC()
	}
}

// peerCountMetricsLoop monitors active peer metrics periodically.
func (s *LibP2PService) peerCountMetricsLoop() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-mesh] panic recovered in peerCountMetricsLoop: %v", r)
		}
	}()
	defer s.wg.Done()
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-s.ctx.Done():
			return
		case <-ticker.C:
			s.peersMu.RLock()
			count := len(s.peers)
			s.peersMu.RUnlock()
			s.stats.DiscoveredPeers.Store(int64(count))
		}
	}
}

// gossipLoop periodically shares known peers with all connected peers (GossipSub simulation).
func (s *LibP2PService) gossipLoop() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-mesh] panic recovered in gossipLoop: %v", r)
		}
	}()
	defer s.wg.Done()
	ticker := time.NewTicker(15 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-s.ctx.Done():
			return
		case <-ticker.C:
			s.peersMu.RLock()
			var knownAddrs []string
			for _, p := range s.peers {
				if len(p.info.Addrs) > 0 {
					knownAddrs = append(knownAddrs, p.info.Addrs[0])
				}
			}
			s.peersMu.RUnlock()

			if len(knownAddrs) > 0 {
				msg := GossipMessage{
					Version:    1,
					NodeID:     s.nodeID,
					KnownPeers: knownAddrs,
					Timestamp:  time.Now().UnixMilli(),
				}
				payload, _ := json.Marshal(msg)
				for _, addr := range knownAddrs {
					// Actual network transmission
					conn, err := net.DialTimeout("udp", addr, 2*time.Second)
					if err == nil {
						conn.Write(payload)
						conn.Close()
					}
				}
				s.stats.MessagesRelayed.Add(1)
				s.stats.BytesRelayed.Add(int64(len(payload) * len(knownAddrs)))
			}
		}
	}
}

// gossipListenerLoop listens for UDP gossip messages.
func (s *LibP2PService) gossipListenerLoop() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-mesh] panic recovered in gossipListenerLoop: %v", r)
		}
	}()
	defer s.wg.Done()

	if len(s.cfg.ListenAddrs) == 0 {
		return
	}
	
	// Since this is an emulation, we will just start a UDP listener on 0.0.0.0:0
	// In a real libp2p, the multiaddr would be used.
	
	addr, err := net.ResolveUDPAddr("udp", ":0") // bind to any available port
	if err != nil {
		log.Printf("[airbridge-mesh] gossip listener address resolution failed: %v", err)
		return
	}

	conn, err := net.ListenUDP("udp", addr)
	if err != nil {
		log.Printf("[airbridge-mesh] gossip listener failed to bind: %v", err)
		return
	}
	s.udpConn = conn
	
	log.Printf("[airbridge-mesh] gossip listener bound to %v", conn.LocalAddr())

	buf := make([]byte, 4096)
	for {
		if s.ctx.Err() != nil {
			return
		}
		
		conn.SetReadDeadline(time.Now().Add(100 * time.Millisecond))
		n, _, err := conn.ReadFromUDP(buf)
		if err != nil {
			if s.ctx.Err() != nil {
				return
			}
			if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
				continue
			}
			return
		}

		var msg GossipMessage
		if err := json.Unmarshal(buf[:n], &msg); err != nil {
			continue // ignore invalid messages
		}

		if msg.NodeID == s.nodeID {
			continue // ignore our own messages
		}

		s.stats.MessagesRelayed.Add(1)
		s.stats.BytesRelayed.Add(int64(n))
		
		s.UpdatePeerLastSeen(msg.NodeID)

		// Discover new peers
		for _, pAddr := range msg.KnownPeers {
			// Basic protection against self-connect loop
			s.peersMu.RLock()
			found := false
			for _, cp := range s.peers {
				for _, a := range cp.info.Addrs {
					if a == pAddr {
						found = true
						break
					}
				}
			}
			s.peersMu.RUnlock()

			if !found {
				// Fire a peer discovered event
				s.emitEvent("", DiscoveryEvent{
					Peer: PeerInfo{
						ID:    fmt.Sprintf("discovered-%s", pAddr),
						Addrs: []string{pAddr},
					},
				})
			}
		}
	}
}

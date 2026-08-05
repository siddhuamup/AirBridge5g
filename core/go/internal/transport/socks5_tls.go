package transport

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"sync"
	"sync/atomic"
	"time"

	"github.com/example/securemesh/core/internal/protocol"
)

// SOCKS5 over TLS transport constants.
const (
	SOCKS5TLSDefaultPort = 1080
	SOCKS5TLSALPN        = "airbridge-socks/1"
)

// SOCKS5TLSStats tracks SOCKS5-over-TLS transport metrics.
type SOCKS5TLSStats struct {
	ActiveConnections atomic.Int64
	TotalConnections  atomic.Int64
	BytesSent         atomic.Int64
	BytesReceived     atomic.Int64
	HandshakeErrors   atomic.Int64
}

// SOCKS5TLSStatsSnapshot is an immutable view.
type SOCKS5TLSStatsSnapshot struct {
	ActiveConnections int64
	TotalConnections  int64
	BytesSent         int64
	BytesReceived     int64
	HandshakeErrors   int64
}

// Snapshot returns a point-in-time copy.
func (s *SOCKS5TLSStats) Snapshot() SOCKS5TLSStatsSnapshot {
	return SOCKS5TLSStatsSnapshot{
		ActiveConnections: s.ActiveConnections.Load(),
		TotalConnections:  s.TotalConnections.Load(),
		BytesSent:         s.BytesSent.Load(),
		BytesReceived:     s.BytesReceived.Load(),
		HandshakeErrors:   s.HandshakeErrors.Load(),
	}
}

// SOCKS5TLSConfig configures the SOCKS5-over-TLS transport.
type SOCKS5TLSConfig struct {
	BindAddress      string
	TLSConfig        *tls.Config
	MaxConnections   int
	DialTimeout      time.Duration
	HandshakeTimeout time.Duration
}

// DefaultSOCKS5TLSConfig returns sensible defaults.
func DefaultSOCKS5TLSConfig() SOCKS5TLSConfig {
	return SOCKS5TLSConfig{
		BindAddress:      fmt.Sprintf("127.0.0.1:%d", SOCKS5TLSDefaultPort),
		MaxConnections:   256,
		DialTimeout:      30 * time.Second,
		HandshakeTimeout: 10 * time.Second,
	}
}

// socks5TLSStream wraps a TLS connection as a Stream.
type socks5TLSStream struct {
	conn  net.Conn
	stats *SOCKS5TLSStats
}

func (s *socks5TLSStream) ReadPacket(ctx context.Context) ([]byte, error) {
	// Length-prefixed read: [4 bytes length][payload]
	lenBuf := make([]byte, 4)
	if _, err := io.ReadFull(s.conn, lenBuf); err != nil {
		return nil, fmt.Errorf("read packet length: %w", err)
	}

	pktLen := int(lenBuf[0])<<24 | int(lenBuf[1])<<16 | int(lenBuf[2])<<8 | int(lenBuf[3])
	if pktLen <= 0 || pktLen > 1<<20 {
		return nil, fmt.Errorf("invalid packet length: %d", pktLen)
	}

	payload := make([]byte, pktLen)
	if _, err := io.ReadFull(s.conn, payload); err != nil {
		return nil, fmt.Errorf("read packet payload: %w", err)
	}

	s.stats.BytesReceived.Add(int64(pktLen + 4))
	return payload, nil
}

func (s *socks5TLSStream) WritePacket(ctx context.Context, packet []byte) error {
	pktLen := len(packet)
	lenBuf := []byte{
		byte(pktLen >> 24), byte(pktLen >> 16),
		byte(pktLen >> 8), byte(pktLen),
	}

	data := append(lenBuf, packet...)
	n, err := s.conn.Write(data)
	if err != nil {
		return fmt.Errorf("write packet: %w", err)
	}
	s.stats.BytesSent.Add(int64(n))
	return nil
}

func (s *socks5TLSStream) Close() error {
	return s.conn.Close()
}

// SOCKS5OverTLS implements the Dialer and Listener interfaces using
// SOCKS5 tunneled over TLS 1.3.
type SOCKS5OverTLS struct {
	TLSConfig *tls.Config
	cfg       SOCKS5TLSConfig
	stats     SOCKS5TLSStats
	listener  net.Listener
	mu        sync.Mutex
	ctx       context.Context
	cancel    context.CancelFunc
}

// NewSOCKS5OverTLS creates a new SOCKS5-over-TLS transport.
func NewSOCKS5OverTLS(cfg SOCKS5TLSConfig) *SOCKS5OverTLS {
	if cfg.TLSConfig != nil {
		cfg.TLSConfig = cfg.TLSConfig.Clone()
		cfg.TLSConfig.NextProtos = []string{SOCKS5TLSALPN}
	}
	return &SOCKS5OverTLS{
		TLSConfig: cfg.TLSConfig,
		cfg:       cfg,
	}
}

// GetStats returns current transport statistics.
func (s *SOCKS5OverTLS) GetStats() SOCKS5TLSStatsSnapshot {
	return s.stats.Snapshot()
}

// Dial connects to a remote peer over SOCKS5-over-TLS.
func (s *SOCKS5OverTLS) Dial(ctx context.Context, endpoint Endpoint, profile protocol.SessionProfile) (Stream, error) {
	if s.TLSConfig == nil {
		return nil, errors.New("TLS config required for SOCKS5-over-TLS transport")
	}

	dialer := &tls.Dialer{
		Config: s.TLSConfig,
	}

	dialCtx, cancel := context.WithTimeout(ctx, s.cfg.DialTimeout)
	defer cancel()

	conn, err := dialer.DialContext(dialCtx, "tcp", endpoint.Address)
	if err != nil {
		s.stats.HandshakeErrors.Add(1)
		return nil, fmt.Errorf("socks5-tls dial %s: %w", endpoint.Address, err)
	}

	s.stats.TotalConnections.Add(1)
	s.stats.ActiveConnections.Add(1)

	stream := &socks5TLSStream{conn: conn, stats: &s.stats}
	return &trackedStream{
		Stream: stream,
		onClose: func() {
			s.stats.ActiveConnections.Add(-1)
		},
	}, nil
}

// Listen starts accepting incoming SOCKS5-over-TLS connections.
func (s *SOCKS5OverTLS) Listen(ctx context.Context, profile protocol.SessionProfile) (<-chan Stream, error) {
	if s.TLSConfig == nil {
		return nil, errors.New("TLS config required for SOCKS5-over-TLS transport")
	}

	s.mu.Lock()
	s.ctx, s.cancel = context.WithCancel(ctx)
	s.mu.Unlock()

	var err error
	s.listener, err = tls.Listen("tcp", s.cfg.BindAddress, s.TLSConfig)
	if err != nil {
		return nil, fmt.Errorf("socks5-tls listen on %s: %w", s.cfg.BindAddress, err)
	}

	log.Printf("[airbridge-socks5-tls] listening on %s", s.cfg.BindAddress)

	streamCh := make(chan Stream, s.cfg.MaxConnections)

	go func() {
		defer close(streamCh)
		for {
			conn, err := s.listener.Accept()
			if err != nil {
				if s.ctx.Err() != nil {
					return
				}
				s.stats.HandshakeErrors.Add(1)
				log.Printf("[airbridge-socks5-tls] accept error: %v", err)
				continue
			}

			if s.stats.ActiveConnections.Load() >= int64(s.cfg.MaxConnections) {
				conn.Close()
				continue
			}

			s.stats.TotalConnections.Add(1)
			s.stats.ActiveConnections.Add(1)

			stream := &trackedStream{
				Stream: &socks5TLSStream{conn: conn, stats: &s.stats},
				onClose: func() {
					s.stats.ActiveConnections.Add(-1)
				},
			}

			select {
			case streamCh <- stream:
			case <-s.ctx.Done():
				stream.Close()
				return
			}
		}
	}()

	go func() {
		<-s.ctx.Done()
		if s.listener != nil {
			s.listener.Close()
		}
	}()

	return streamCh, nil
}

// Shutdown gracefully shuts down the transport.
func (s *SOCKS5OverTLS) Shutdown() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cancel != nil {
		s.cancel()
	}
	if s.listener != nil {
		return s.listener.Close()
	}
	return nil
}

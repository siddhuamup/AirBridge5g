package transport

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"log"
	"sync"
	"sync/atomic"
	"time"

	"github.com/example/securemesh/core/internal/protocol"
	"github.com/quic-go/quic-go"
)

// QUIC transport constants.
const (
	QUICDefaultPort      = 4433
	QUICMaxStreams       = 256
	QUICIdleTimeout      = 30 * time.Second
	QUICKeepAlive        = 10 * time.Second
	QUICHandshakeTimeout = 10 * time.Second
	QUICALPNAirBridge    = "airbridge/1"
)

// QUICStats tracks QUIC transport metrics.
type QUICStats struct {
	ActiveStreams   atomic.Int64
	TotalStreams    atomic.Int64
	BytesSent       atomic.Int64
	BytesReceived   atomic.Int64
	HandshakeErrors atomic.Int64
	StreamErrors    atomic.Int64
}

// QUICStatsSnapshot is an immutable point-in-time copy.
type QUICStatsSnapshot struct {
	ActiveStreams   int64
	TotalStreams    int64
	BytesSent       int64
	BytesReceived   int64
	HandshakeErrors int64
	StreamErrors    int64
}

// Snapshot returns a point-in-time copy of stats.
func (s *QUICStats) Snapshot() QUICStatsSnapshot {
	return QUICStatsSnapshot{
		ActiveStreams:   s.ActiveStreams.Load(),
		TotalStreams:    s.TotalStreams.Load(),
		BytesSent:       s.BytesSent.Load(),
		BytesReceived:   s.BytesReceived.Load(),
		HandshakeErrors: s.HandshakeErrors.Load(),
		StreamErrors:    s.StreamErrors.Load(),
	}
}

// QUICConfig configures the QUIC transport layer.
type QUICConfig struct {
	BindAddress      string
	TLSConfig        *tls.Config
	MaxStreams       int
	IdleTimeout      time.Duration
	KeepAlive        time.Duration
	HandshakeTimeout time.Duration
	EnableMigration  bool // Support connection migration for network handovers
}

// DefaultQUICConfig returns sensible defaults.
func DefaultQUICConfig() QUICConfig {
	return QUICConfig{
		BindAddress:      fmt.Sprintf("0.0.0.0:%d", QUICDefaultPort),
		MaxStreams:       QUICMaxStreams,
		IdleTimeout:      QUICIdleTimeout,
		KeepAlive:        QUICKeepAlive,
		HandshakeTimeout: QUICHandshakeTimeout,
		EnableMigration:  true,
	}
}

// quicStream wraps a quic.Stream to implement the Stream interface.
type quicStream struct {
	stream *quic.Stream
	stats  *QUICStats
}

func newQUICStream(stream *quic.Stream, stats *QUICStats) *quicStream {
	return &quicStream{
		stream: stream,
		stats:  stats,
	}
}

func (s *quicStream) ReadPacket(ctx context.Context) ([]byte, error) {
	// Read length-prefixed packet: [4 bytes length][payload]
	lenBuf := make([]byte, 4)
	if _, err := io.ReadFull(s.stream, lenBuf); err != nil {
		return nil, fmt.Errorf("read packet length: %w", err)
	}

	pktLen := int(lenBuf[0])<<24 | int(lenBuf[1])<<16 | int(lenBuf[2])<<8 | int(lenBuf[3])
	if pktLen <= 0 || pktLen > 1<<20 { // Max 1MB packet
		return nil, fmt.Errorf("invalid packet length: %d", pktLen)
	}

	payload := make([]byte, pktLen)
	if _, err := io.ReadFull(s.stream, payload); err != nil {
		return nil, fmt.Errorf("read packet payload: %w", err)
	}

	s.stats.BytesReceived.Add(int64(pktLen + 4))
	return payload, nil
}

func (s *quicStream) WritePacket(ctx context.Context, packet []byte) error {
	pktLen := len(packet)
	lenBuf := []byte{
		byte(pktLen >> 24), byte(pktLen >> 16),
		byte(pktLen >> 8), byte(pktLen),
	}

	// Write length prefix + payload atomically
	data := append(lenBuf, packet...)
	n, err := s.stream.Write(data)
	if err != nil {
		return fmt.Errorf("write packet: %w", err)
	}
	s.stats.BytesSent.Add(int64(n))
	return nil
}

func (s *quicStream) Close() error {
	return s.stream.Close()
}

// QUICTransport implements the Dialer and Listener interfaces using QUIC.
type QUICTransport struct {
	TLSConfig *tls.Config
	cfg       QUICConfig
	stats     QUICStats
	listener  *quic.Listener
	mu        sync.Mutex
	ctx       context.Context
	cancel    context.CancelFunc
	wg        sync.WaitGroup
	streamCh  chan Stream
}

// NewQUICTransport creates a new QUIC transport with the given TLS config.
func NewQUICTransport(cfg QUICConfig) *QUICTransport {
	if cfg.TLSConfig != nil {
		cfg.TLSConfig = cfg.TLSConfig.Clone()
		cfg.TLSConfig.NextProtos = []string{QUICALPNAirBridge}
	}
	return &QUICTransport{
		TLSConfig: cfg.TLSConfig,
		cfg:       cfg,
	}
}

// GetStats returns current transport statistics.
func (t *QUICTransport) GetStats() QUICStatsSnapshot {
	return t.stats.Snapshot()
}

// Dial connects to a remote peer via QUIC transport.
func (t *QUICTransport) Dial(ctx context.Context, endpoint Endpoint, profile protocol.SessionProfile) (Stream, error) {
	if t.TLSConfig == nil {
		return nil, errors.New("TLS config required for QUIC transport")
	}

	quicCfg := &quic.Config{
		HandshakeIdleTimeout: t.cfg.HandshakeTimeout,
		MaxIdleTimeout:       t.cfg.IdleTimeout,
		KeepAlivePeriod:      t.cfg.KeepAlive,
	}

	conn, err := quic.DialAddr(ctx, endpoint.Address, t.TLSConfig, quicCfg)
	if err != nil {
		t.stats.HandshakeErrors.Add(1)
		return nil, fmt.Errorf("quic dial %s: %w", endpoint.Address, err)
	}

	stream, err := conn.OpenStreamSync(ctx)
	if err != nil {
		conn.CloseWithError(1, err.Error())
		return nil, fmt.Errorf("quic open stream: %w", err)
	}

	t.stats.TotalStreams.Add(1)
	t.stats.ActiveStreams.Add(1)

	qStream := newQUICStream(stream, &t.stats)
	return &trackedStream{
		Stream: qStream,
		onClose: func() {
			t.stats.ActiveStreams.Add(-1)
		},
	}, nil
}

// Listen starts accepting incoming QUIC connections.
func (t *QUICTransport) Listen(ctx context.Context, profile protocol.SessionProfile) (<-chan Stream, error) {
	if t.TLSConfig == nil {
		return nil, errors.New("TLS config required for QUIC transport")
	}

	t.mu.Lock()
	t.ctx, t.cancel = context.WithCancel(ctx)
	t.mu.Unlock()

	quicCfg := &quic.Config{
		HandshakeIdleTimeout: t.cfg.HandshakeTimeout,
		MaxIdleTimeout:       t.cfg.IdleTimeout,
		KeepAlivePeriod:      t.cfg.KeepAlive,
	}

	var err error
	t.listener, err = quic.ListenAddr(t.cfg.BindAddress, t.TLSConfig, quicCfg)
	if err != nil {
		return nil, fmt.Errorf("quic listen on %s: %w", t.cfg.BindAddress, err)
	}

	log.Printf("[airbridge-quic] listening on %s (ALPN=%s)", t.cfg.BindAddress, QUICALPNAirBridge)

	t.streamCh = make(chan Stream, t.cfg.MaxStreams)

	t.wg.Add(1)
	go func() {
		defer t.wg.Done()
		defer close(t.streamCh)
		for {
			conn, err := t.listener.Accept(t.ctx)
			if err != nil {
				if t.ctx.Err() != nil {
					return // graceful shutdown
				}
				t.stats.HandshakeErrors.Add(1)
				log.Printf("[airbridge-quic] accept connection error: %v", err)
				continue
			}

			t.wg.Add(1)
			go func(c *quic.Conn) {
				defer t.wg.Done()
				for {
					stream, err := c.AcceptStream(t.ctx)
					if err != nil {
						if t.ctx.Err() == nil {
							log.Printf("[airbridge-quic] accept stream error: %v", err)
						}
						return
					}

					if t.stats.ActiveStreams.Load() >= int64(t.cfg.MaxStreams) {
						t.stats.StreamErrors.Add(1)
						stream.Close()
						continue
					}

					t.stats.TotalStreams.Add(1)
					t.stats.ActiveStreams.Add(1)

					qStream := newQUICStream(stream, &t.stats)
					tracked := &trackedStream{
						Stream: qStream,
						onClose: func() {
							t.stats.ActiveStreams.Add(-1)
						},
					}

					select {
					case t.streamCh <- tracked:
					case <-t.ctx.Done():
						tracked.Close()
						return
					}
				}
			}(conn)
		}
	}()

	// Shutdown listener when context is cancelled
	go func() {
		<-t.ctx.Done()
		if t.listener != nil {
			t.listener.Close()
		}
	}()

	return t.streamCh, nil
}

// Shutdown gracefully shuts down the QUIC transport.
func (t *QUICTransport) Shutdown() error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.cancel != nil {
		t.cancel()
	}
	t.wg.Wait()
	if t.listener != nil {
		return t.listener.Close()
	}
	return nil
}

// trackedStream wraps a Stream to call onClose when closed.
type trackedStream struct {
	Stream
	onClose   func()
	closeOnce sync.Once
}

func (s *trackedStream) Close() error {
	err := s.Stream.Close()
	s.closeOnce.Do(func() {
		if s.onClose != nil {
			s.onClose()
		}
	})
	return err
}

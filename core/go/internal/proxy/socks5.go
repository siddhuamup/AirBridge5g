// Package proxy implements the AirBridge 5G SOCKS5 proxy server
// with TLS 1.3 wrapping and peer authentication.
package proxy

import (
	"context"
	"crypto/tls"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"sync"
	"sync/atomic"
	"time"

	"github.com/example/securemesh/core/internal/privacy"
)

// SOCKS5 protocol constants (RFC 1928).
const (
	socks5Version       = 0x05
	socks5AuthNone      = 0x00
	socks5AuthPassword  = 0x02
	socks5AuthNoAccept  = 0xFF
	socks5CmdConnect    = 0x01
	socks5AtypIPv4      = 0x01
	socks5AtypDomain    = 0x03
	socks5AtypIPv6      = 0x04
	socks5ReplySuccess  = 0x00
	socks5ReplyFail     = 0x01
	socks5ReplyNotAllow = 0x02
	socks5ReplyNetUnreach = 0x03
	socks5ReplyHostUnreach = 0x04
	socks5ReplyConnRefused = 0x05
)

// Errors returned by the SOCKS5 proxy.
var (
	ErrUnsupportedVersion = errors.New("unsupported SOCKS version")
	ErrUnsupportedCmd     = errors.New("unsupported SOCKS command")
	ErrAuthFailed         = errors.New("authentication failed")
	ErrMaxConnections     = errors.New("max connections reached")
)

// Authenticator validates peer credentials during SOCKS5 handshake.
type Authenticator interface {
	Validate(username, password string) bool
}

// TokenAuthenticator validates connections using a shared token.
type TokenAuthenticator struct {
	mu     sync.RWMutex
	tokens map[string]string // username -> token
}

// NewTokenAuthenticator creates an authenticator with pre-shared tokens.
func NewTokenAuthenticator(tokens map[string]string) *TokenAuthenticator {
	copied := make(map[string]string, len(tokens))
	for k, v := range tokens {
		copied[k] = v
	}
	return &TokenAuthenticator{tokens: copied}
}

// Validate checks username/password against registered tokens.
func (a *TokenAuthenticator) Validate(username, password string) bool {
	a.mu.RLock()
	defer a.mu.RUnlock()
	expected, ok := a.tokens[username]
	return ok && expected == password
}

// AddToken registers a new peer credential.
func (a *TokenAuthenticator) AddToken(username, token string) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.tokens[username] = token
}

// RemoveToken removes a peer credential.
func (a *TokenAuthenticator) RemoveToken(username string) {
	a.mu.Lock()
	defer a.mu.Unlock()
	delete(a.tokens, username)
}

// Metrics tracks proxy server statistics.
type Metrics struct {
	ActiveConnections   atomic.Int64
	TotalConnections    atomic.Int64
	BytesIn             atomic.Int64
	BytesOut            atomic.Int64
	AuthFailures        atomic.Int64
	ConnectionErrors    atomic.Int64
}

// Snapshot returns a point-in-time copy of metrics.
func (m *Metrics) Snapshot() MetricsSnapshot {
	return MetricsSnapshot{
		ActiveConnections: m.ActiveConnections.Load(),
		TotalConnections:  m.TotalConnections.Load(),
		BytesIn:           m.BytesIn.Load(),
		BytesOut:          m.BytesOut.Load(),
		AuthFailures:      m.AuthFailures.Load(),
		ConnectionErrors:  m.ConnectionErrors.Load(),
	}
}

// MetricsSnapshot is an immutable point-in-time copy of metrics.
type MetricsSnapshot struct {
	ActiveConnections int64
	TotalConnections  int64
	BytesIn           int64
	BytesOut          int64
	AuthFailures      int64
	ConnectionErrors  int64
}

// ServerConfig configures the SOCKS5 proxy server.
type ServerConfig struct {
	BindAddress    string
	TLSConfig      *tls.Config
	Auth           Authenticator
	MaxConnections int
	DialTimeout    time.Duration
	RelayBufSize   int
	TTLNormalizer  *privacy.TTLNormalizer
	Fragmenter     *privacy.Fragmenter
	UAHarmonizer   *privacy.UAHarmonizer
}

// DefaultServerConfig returns sensible defaults.
func DefaultServerConfig() ServerConfig {
	return ServerConfig{
		BindAddress:    "127.0.0.1:1080",
		MaxConnections: 256,
		DialTimeout:    30 * time.Second,
		RelayBufSize:   32 * 1024, // 32KB relay buffer
	}
}

// Server is the AirBridge SOCKS5 proxy server.
type Server struct {
	cfg      ServerConfig
	metrics  Metrics
	listener net.Listener
	mu       sync.Mutex
	ctx      context.Context
	cancel   context.CancelFunc
	wg       sync.WaitGroup
}

// NewServer creates a new SOCKS5 proxy server.
func NewServer(cfg ServerConfig) *Server {
	if cfg.MaxConnections <= 0 {
		cfg.MaxConnections = 256
	}
	if cfg.DialTimeout <= 0 {
		cfg.DialTimeout = 30 * time.Second
	}
	if cfg.RelayBufSize <= 0 {
		cfg.RelayBufSize = 32 * 1024
	}
	return &Server{cfg: cfg}
}

// GetMetrics returns a snapshot of current server metrics.
func (s *Server) GetMetrics() MetricsSnapshot {
	return s.metrics.Snapshot()
}

// ListenAndServe starts the SOCKS5 proxy server.
func (s *Server) ListenAndServe(ctx context.Context) error {
	s.mu.Lock()
	s.ctx, s.cancel = context.WithCancel(ctx)
	s.mu.Unlock()

	var err error
	if s.cfg.TLSConfig != nil {
		s.listener, err = tls.Listen("tcp", s.cfg.BindAddress, s.cfg.TLSConfig)
	} else {
		s.listener, err = net.Listen("tcp", s.cfg.BindAddress)
	}
	if err != nil {
		return fmt.Errorf("socks5 listen: %w", err)
	}

	log.Printf("[airbridge-proxy] SOCKS5 server listening on %s (TLS=%v)",
		s.cfg.BindAddress, s.cfg.TLSConfig != nil)

	go func() {
		<-s.ctx.Done()
		_ = s.listener.Close()
	}()

	for {
		conn, err := s.listener.Accept()
		if err != nil {
			if s.ctx.Err() != nil {
				break // graceful shutdown
			}
			s.metrics.ConnectionErrors.Add(1)
			log.Printf("[airbridge-proxy] accept error: %v", err)
			continue
		}

		if s.metrics.ActiveConnections.Load() >= int64(s.cfg.MaxConnections) {
			s.metrics.ConnectionErrors.Add(1)
			_ = conn.Close()
			continue
		}

		s.metrics.TotalConnections.Add(1)
		s.metrics.ActiveConnections.Add(1)
		s.wg.Add(1)

		go func() {
			defer s.wg.Done()
			defer s.metrics.ActiveConnections.Add(-1)
			s.handleConnection(s.ctx, conn)
		}()
	}

	s.wg.Wait()
	return nil
}

// Shutdown gracefully shuts down the proxy server.
func (s *Server) Shutdown(ctx context.Context) error {
	s.mu.Lock()
	if s.cancel != nil {
		s.cancel()
	}
	s.mu.Unlock()

	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// handleConnection processes a single SOCKS5 client connection.
func (s *Server) handleConnection(ctx context.Context, conn net.Conn) {
	defer conn.Close()

	// Step 1: Version + auth method negotiation
	if err := s.negotiate(conn); err != nil {
		log.Printf("[airbridge-proxy] negotiate error: %v", err)
		return
	}

	// Step 2: Read SOCKS5 request
	destAddr, err := s.readRequest(conn)
	if err != nil {
		log.Printf("[airbridge-proxy] request error: %v", err)
		return
	}

	// Step 3: Connect to target
	target, err := net.DialTimeout("tcp", destAddr, s.cfg.DialTimeout)
	if err != nil {
		s.sendReply(conn, socks5ReplyHostUnreach, "0.0.0.0", 0)
		s.metrics.ConnectionErrors.Add(1)
		return
	}
	defer target.Close()

	// Step 4: Send success reply
	localAddr := target.LocalAddr().(*net.TCPAddr)
	s.sendReply(conn, socks5ReplySuccess, localAddr.IP.String(), localAddr.Port)

	// Step 5: Relay data bidirectionally
	s.relay(ctx, conn, target)
}

// negotiate handles the SOCKS5 version and auth method negotiation.
func (s *Server) negotiate(conn net.Conn) error {
	// Read: VER | NMETHODS | METHODS...
	header := make([]byte, 2)
	if _, err := io.ReadFull(conn, header); err != nil {
		return fmt.Errorf("read header: %w", err)
	}

	if header[0] != socks5Version {
		return ErrUnsupportedVersion
	}

	nMethods := int(header[1])
	methods := make([]byte, nMethods)
	if _, err := io.ReadFull(conn, methods); err != nil {
		return fmt.Errorf("read methods: %w", err)
	}

	// If authenticator is set, require username/password
	if s.cfg.Auth != nil {
		hasPasswordAuth := false
		for _, m := range methods {
			if m == socks5AuthPassword {
				hasPasswordAuth = true
				break
			}
		}
		if !hasPasswordAuth {
			_, _ = conn.Write([]byte{socks5Version, socks5AuthNoAccept})
			return ErrAuthFailed
		}

		// Select password auth
		if _, err := conn.Write([]byte{socks5Version, socks5AuthPassword}); err != nil {
			return err
		}

		return s.authenticatePassword(conn)
	}

	// No auth required
	_, err := conn.Write([]byte{socks5Version, socks5AuthNone})
	return err
}

// authenticatePassword handles RFC 1929 username/password sub-negotiation.
func (s *Server) authenticatePassword(conn net.Conn) error {
	// Read: VER(1) | ULEN(1) | UNAME(ULEN) | PLEN(1) | PASSWD(PLEN)
	verBuf := make([]byte, 1)
	if _, err := io.ReadFull(conn, verBuf); err != nil {
		return err
	}

	ulenBuf := make([]byte, 1)
	if _, err := io.ReadFull(conn, ulenBuf); err != nil {
		return err
	}
	uname := make([]byte, ulenBuf[0])
	if _, err := io.ReadFull(conn, uname); err != nil {
		return err
	}

	plenBuf := make([]byte, 1)
	if _, err := io.ReadFull(conn, plenBuf); err != nil {
		return err
	}
	passwd := make([]byte, plenBuf[0])
	if _, err := io.ReadFull(conn, passwd); err != nil {
		return err
	}

	if !s.cfg.Auth.Validate(string(uname), string(passwd)) {
		s.metrics.AuthFailures.Add(1)
		if _, err := conn.Write([]byte{0x01, 0x01}); err != nil {
			return fmt.Errorf("write auth failure response: %w", err)
		}
		return ErrAuthFailed
	}

	_, err := conn.Write([]byte{0x01, 0x00}) // auth success
	return err
}

// readRequest reads and parses the SOCKS5 CONNECT request.
func (s *Server) readRequest(conn net.Conn) (string, error) {
	// Read: VER(1) | CMD(1) | RSV(1) | ATYP(1)
	header := make([]byte, 4)
	if _, err := io.ReadFull(conn, header); err != nil {
		return "", fmt.Errorf("read request header: %w", err)
	}

	if header[0] != socks5Version {
		return "", ErrUnsupportedVersion
	}
	if header[1] != socks5CmdConnect {
		s.sendReply(conn, socks5ReplyNotAllow, "0.0.0.0", 0)
		return "", ErrUnsupportedCmd
	}

	var host string
	switch header[3] {
	case socks5AtypIPv4:
		addr := make([]byte, 4)
		if _, err := io.ReadFull(conn, addr); err != nil {
			return "", err
		}
		host = net.IP(addr).String()

	case socks5AtypDomain:
		lenBuf := make([]byte, 1)
		if _, err := io.ReadFull(conn, lenBuf); err != nil {
			return "", err
		}
		domain := make([]byte, lenBuf[0])
		if _, err := io.ReadFull(conn, domain); err != nil {
			return "", err
		}
		host = string(domain)

	case socks5AtypIPv6:
		addr := make([]byte, 16)
		if _, err := io.ReadFull(conn, addr); err != nil {
			return "", err
		}
		host = net.IP(addr).String()

	default:
		return "", fmt.Errorf("unsupported address type: %d", header[3])
	}

	// Read port (2 bytes, big-endian)
	portBuf := make([]byte, 2)
	if _, err := io.ReadFull(conn, portBuf); err != nil {
		return "", err
	}
	port := binary.BigEndian.Uint16(portBuf)

	return fmt.Sprintf("%s:%d", host, port), nil
}

// sendReply sends a SOCKS5 reply to the client.
func (s *Server) sendReply(conn net.Conn, status byte, bindIP string, bindPort int) error {
	ip := net.ParseIP(bindIP)
	if ip == nil {
		ip = net.IPv4zero
	}
	ip4 := ip.To4()

	var reply []byte
	if ip4 != nil {
		reply = make([]byte, 10)
		reply[0] = socks5Version
		reply[1] = status
		reply[2] = 0x00
		reply[3] = socks5AtypIPv4
		copy(reply[4:8], ip4)
		reply[8] = byte(bindPort >> 8)
		reply[9] = byte(bindPort & 0xFF)
	} else {
		ip6 := ip.To16()
		if ip6 == nil {
			ip6 = net.IPv6zero
		}
		reply = make([]byte, 22)
		reply[0] = socks5Version
		reply[1] = status
		reply[2] = 0x00
		reply[3] = socks5AtypIPv6
		copy(reply[4:20], ip6)
		reply[20] = byte(bindPort >> 8)
		reply[21] = byte(bindPort & 0xFF)
	}
	_, err := conn.Write(reply)
	return err
}

type fragmentingWriter struct {
	w          io.Writer
	fragmenter *privacy.Fragmenter
}

func (fw *fragmentingWriter) Write(p []byte) (n int, err error) {
	if fw.fragmenter == nil || !fw.fragmenter.IsEnabled() {
		return fw.w.Write(p)
	}
	frags, err := fw.fragmenter.Fragment(p)
	if err != nil || len(frags) == 0 {
		return fw.w.Write(p)
	}
	total := 0
	for _, frag := range frags {
		nw, err := fw.w.Write(frag)
		total += nw
		if err != nil {
			return total, err
		}
	}
	return total, nil
}

type uaHarmonizingReader struct {
	r            io.Reader
	uaHarmonizer *privacy.UAHarmonizer
	inspected    bool
	buf          []byte
	offset       int
}

func (u *uaHarmonizingReader) Read(p []byte) (n int, err error) {
	if u.uaHarmonizer == nil || !u.uaHarmonizer.IsEnabled() || u.inspected {
		if len(u.buf) > 0 {
			n = copy(p, u.buf[u.offset:])
			u.offset += n
			if u.offset >= len(u.buf) {
				u.buf = nil
			}
			return n, nil
		}
		return u.r.Read(p)
	}

	u.inspected = true
	temp := make([]byte, 4096)
	nr, rErr := u.r.Read(temp)
	if nr > 0 {
		data := temp[:nr]
		if harmonized, hErr := u.uaHarmonizer.HarmonizeRawHTTP(data); hErr == nil && len(harmonized) > 0 {
			data = harmonized
		}
		u.buf = data
		u.offset = 0
		n = copy(p, u.buf)
		u.offset += n
		if u.offset >= len(u.buf) {
			u.buf = nil
		}
		return n, rErr
	}
	return nr, rErr
}

// relay copies data bidirectionally between client and target.
func (s *Server) relay(ctx context.Context, client, target net.Conn) {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	var once sync.Once
	closeSockets := func() {
		once.Do(func() {
			_ = client.SetDeadline(time.Now())
			_ = target.SetDeadline(time.Now())
		})
	}

	if s.cfg.TTLNormalizer != nil && s.cfg.TTLNormalizer.IsEnabled() {
		// Mock IPv4 header for TTL normalization tracking
		mockPacket := make([]byte, 20)
		mockPacket[0] = 0x45 // IPv4, IHL 5
		mockPacket[8] = 128  // Original Windows TTL
		_, _ = s.cfg.TTLNormalizer.NormalizePacket(mockPacket)
	}

	var wg sync.WaitGroup
	wg.Add(2)

	// client → target (with packet fragmentation and UA harmonization if enabled)
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Printf("[airbridge-proxy] panic recovered in client->target relay: %v", r)
			}
			wg.Done()
			cancel()
			closeSockets()
		}()
		dstWriter := io.Writer(target)
		if s.cfg.Fragmenter != nil {
			dstWriter = &fragmentingWriter{w: target, fragmenter: s.cfg.Fragmenter}
		}
		srcReader := io.Reader(client)
		if s.cfg.UAHarmonizer != nil {
			srcReader = &uaHarmonizingReader{r: client, uaHarmonizer: s.cfg.UAHarmonizer}
		}
		n, _ := io.CopyBuffer(dstWriter, srcReader, make([]byte, s.cfg.RelayBufSize))
		s.metrics.BytesIn.Add(n)
	}()

	// target → client
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Printf("[airbridge-proxy] panic recovered in target->client relay: %v", r)
			}
			wg.Done()
			cancel()
			closeSockets()
		}()
		n, _ := io.CopyBuffer(client, target, make([]byte, s.cfg.RelayBufSize))
		s.metrics.BytesOut.Add(n)
	}()

	// Context cancellation watchdog
	relayDone := make(chan struct{})
	go func() {
		select {
		case <-ctx.Done():
			closeSockets()
		case <-relayDone:
		}
	}()

	wg.Wait()
	close(relayDone)
}

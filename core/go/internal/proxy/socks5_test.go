package proxy

import (
	"context"
	"fmt"
	"net"
	"testing"
	"time"
)

func TestNewServer(t *testing.T) {
	cfg := DefaultServerConfig()
	server := NewServer(cfg)
	if server == nil {
		t.Fatal("NewServer returned nil")
	}
}

func TestNewServerDefaults(t *testing.T) {
	cfg := ServerConfig{} // Zero values
	server := NewServer(cfg)
	if server.cfg.MaxConnections != 256 {
		t.Errorf("expected MaxConnections=256, got %d", server.cfg.MaxConnections)
	}
	if server.cfg.DialTimeout != 30*time.Second {
		t.Errorf("expected DialTimeout=30s, got %v", server.cfg.DialTimeout)
	}
	if server.cfg.RelayBufSize != 32*1024 {
		t.Errorf("expected RelayBufSize=32768, got %d", server.cfg.RelayBufSize)
	}
}

func TestTokenAuthenticator(t *testing.T) {
	tokens := map[string]string{
		"user1": "token1",
		"user2": "token2",
	}
	auth := NewTokenAuthenticator(tokens)

	tests := []struct {
		name     string
		user     string
		pass     string
		expected bool
	}{
		{"valid user1", "user1", "token1", true},
		{"valid user2", "user2", "token2", true},
		{"wrong password", "user1", "wrong", false},
		{"unknown user", "user3", "token3", false},
		{"empty user", "", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := auth.Validate(tt.user, tt.pass)
			if result != tt.expected {
				t.Errorf("Validate(%q, %q) = %v, want %v", tt.user, tt.pass, result, tt.expected)
			}
		})
	}
}

func TestTokenAuthenticatorAddRemove(t *testing.T) {
	auth := NewTokenAuthenticator(map[string]string{})

	if auth.Validate("new", "token") {
		t.Error("should not validate unknown user")
	}

	auth.AddToken("new", "token")
	if !auth.Validate("new", "token") {
		t.Error("should validate after AddToken")
	}

	auth.RemoveToken("new")
	if auth.Validate("new", "token") {
		t.Error("should not validate after RemoveToken")
	}
}

func TestMetricsSnapshot(t *testing.T) {
	m := &Metrics{}
	m.ActiveConnections.Store(5)
	m.TotalConnections.Store(100)
	m.BytesIn.Store(1024)
	m.BytesOut.Store(2048)
	m.AuthFailures.Store(3)
	m.ConnectionErrors.Store(7)

	snap := m.Snapshot()
	if snap.ActiveConnections != 5 {
		t.Errorf("ActiveConnections = %d, want 5", snap.ActiveConnections)
	}
	if snap.TotalConnections != 100 {
		t.Errorf("TotalConnections = %d, want 100", snap.TotalConnections)
	}
	if snap.BytesIn != 1024 {
		t.Errorf("BytesIn = %d, want 1024", snap.BytesIn)
	}
	if snap.BytesOut != 2048 {
		t.Errorf("BytesOut = %d, want 2048", snap.BytesOut)
	}
}

func TestServerListenAndShutdown(t *testing.T) {
	// Find a free port
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("find free port: %v", err)
	}
	addr := listener.Addr().String()
	listener.Close()

	cfg := DefaultServerConfig()
	cfg.BindAddress = addr
	server := NewServer(cfg)

	ctx, cancel := context.WithCancel(context.Background())

	errCh := make(chan error, 1)
	go func() {
		errCh <- server.ListenAndServe(ctx)
	}()

	// Wait for server to start
	time.Sleep(100 * time.Millisecond)

	// Verify server is listening
	conn, err := net.DialTimeout("tcp", addr, 2*time.Second)
	if err != nil {
		t.Fatalf("connect to server: %v", err)
	}
	conn.Close()

	// Shutdown
	cancel()
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()
	server.Shutdown(shutdownCtx)

	select {
	case err := <-errCh:
		if err != nil {
			t.Logf("server exited with: %v (expected on shutdown)", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("server did not shut down in time")
	}
}

func TestSOCKS5Handshake(t *testing.T) {
	// Start server without auth
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	addr := listener.Addr().String()
	listener.Close()

	cfg := DefaultServerConfig()
	cfg.BindAddress = addr
	server := NewServer(cfg)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go server.ListenAndServe(ctx)
	time.Sleep(100 * time.Millisecond)

	// Connect and perform SOCKS5 handshake
	conn, err := net.DialTimeout("tcp", addr, 2*time.Second)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer conn.Close()

	// Send: VER=5, NMETHODS=1, METHOD=NoAuth
	_, err = conn.Write([]byte{0x05, 0x01, 0x00})
	if err != nil {
		t.Fatalf("send handshake: %v", err)
	}

	// Read: VER=5, METHOD=NoAuth
	reply := make([]byte, 2)
	conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, err = conn.Read(reply)
	if err != nil {
		t.Fatalf("read handshake reply: %v", err)
	}

	if reply[0] != 0x05 {
		t.Errorf("expected SOCKS version 5, got %d", reply[0])
	}
	if reply[1] != 0x00 {
		t.Errorf("expected NoAuth method, got %d", reply[1])
	}
}

func TestSOCKS5ConnectRequest(t *testing.T) {
	// Start a simple echo server as the target
	echoListener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("echo listen: %v", err)
	}
	defer echoListener.Close()
	echoAddr := echoListener.Addr().(*net.TCPAddr)

	go func() {
		for {
			conn, err := echoListener.Accept()
			if err != nil {
				return
			}
			go func(c net.Conn) {
				defer c.Close()
				buf := make([]byte, 1024)
				n, _ := c.Read(buf)
				if n > 0 {
					c.Write(buf[:n])
				}
			}(conn)
		}
	}()

	// Start SOCKS5 server
	proxyListener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("proxy listen: %v", err)
	}
	proxyAddr := proxyListener.Addr().String()
	proxyListener.Close()

	cfg := DefaultServerConfig()
	cfg.BindAddress = proxyAddr
	server := NewServer(cfg)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go server.ListenAndServe(ctx)
	time.Sleep(100 * time.Millisecond)

	// Connect through SOCKS5
	conn, err := net.DialTimeout("tcp", proxyAddr, 2*time.Second)
	if err != nil {
		t.Fatalf("connect to proxy: %v", err)
	}
	defer conn.Close()
	conn.SetDeadline(time.Now().Add(5 * time.Second))

	// Handshake
	conn.Write([]byte{0x05, 0x01, 0x00})
	reply := make([]byte, 2)
	conn.Read(reply)

	// CONNECT to echo server via IPv4
	ip := echoAddr.IP.To4()
	port := echoAddr.Port
	request := []byte{
		0x05, 0x01, 0x00, 0x01, // VER, CMD=CONNECT, RSV, ATYP=IPv4
		ip[0], ip[1], ip[2], ip[3], // IP
		byte(port >> 8), byte(port & 0xFF), // Port
	}
	conn.Write(request)

	// Read connect reply
	connectReply := make([]byte, 10)
	_, err = conn.Read(connectReply)
	if err != nil {
		t.Fatalf("read connect reply: %v", err)
	}

	if connectReply[1] != 0x00 {
		t.Fatalf("CONNECT failed with status %d", connectReply[1])
	}

	// Send data through the proxy and verify echo
	testData := []byte("hello airbridge")
	conn.Write(testData)

	echoReply := make([]byte, len(testData))
	n, err := conn.Read(echoReply)
	if err != nil {
		t.Fatalf("read echo: %v", err)
	}

	if string(echoReply[:n]) != string(testData) {
		t.Errorf("echo mismatch: got %q, want %q", string(echoReply[:n]), string(testData))
	}

	// Verify metrics
	metrics := server.GetMetrics()
	if metrics.TotalConnections < 1 {
		t.Errorf("expected at least 1 total connection, got %d", metrics.TotalConnections)
	}

	fmt.Printf("  ✓ SOCKS5 proxy test passed: relayed %d bytes\n", n)
}

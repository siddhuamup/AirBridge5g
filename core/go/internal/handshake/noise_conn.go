package handshake

import (
	"context"
	"fmt"
	"io"
	"log"
	"net"
	"encoding/binary"
	"time"

	"github.com/flynn/noise"
	"github.com/example/securemesh/core/internal/protocol"
)

const (
	// MaxHandshakePayload is the maximum size of a Noise handshake message.
	MaxHandshakePayload = 65535
	// HandshakeTimeout is the deadline for completing the full handshake.
	HandshakeTimeout = 10 * time.Second
)

// SecureConn wraps a net.Conn with Noise protocol encryption.
// After handshake, all reads/writes are encrypted via CipherState.
type SecureConn struct {
	raw    net.Conn
	send   *noise.CipherState
	recv   *noise.CipherState
	peerID []byte // Remote peer's static public key
}

// Read decrypts incoming data from the Noise-encrypted connection.
func (sc *SecureConn) Read(p []byte) (int, error) {
	// Read length-prefixed encrypted frame: [2 bytes len][ciphertext]
	lenBuf := make([]byte, 2)
	if _, err := io.ReadFull(sc.raw, lenBuf); err != nil {
		return 0, err
	}
	frameLen := int(binary.BigEndian.Uint16(lenBuf))
	if frameLen <= 0 || frameLen > MaxHandshakePayload {
		return 0, fmt.Errorf("invalid frame length: %d", frameLen)
	}

	ciphertext := make([]byte, frameLen)
	if _, err := io.ReadFull(sc.raw, ciphertext); err != nil {
		return 0, err
	}

	plaintext, err := sc.recv.Decrypt(nil, nil, ciphertext)
	if err != nil {
		return 0, fmt.Errorf("noise decrypt: %w", err)
	}

	n := copy(p, plaintext)
	return n, nil
}

// Write encrypts outgoing data via the Noise CipherState.
func (sc *SecureConn) Write(p []byte) (int, error) {
	ciphertext, err := sc.send.Encrypt(nil, nil, p)
	if err != nil {
		return 0, fmt.Errorf("noise encrypt: %w", err)
	}

	// Write length-prefixed encrypted frame
	lenBuf := make([]byte, 2)
	binary.BigEndian.PutUint16(lenBuf, uint16(len(ciphertext)))

	if _, err := sc.raw.Write(lenBuf); err != nil {
		return 0, err
	}
	if _, err := sc.raw.Write(ciphertext); err != nil {
		return 0, err
	}

	return len(p), nil
}

// Close closes the underlying connection.
func (sc *SecureConn) Close() error {
	return sc.raw.Close()
}

// PeerStaticKey returns the remote peer's static public key.
func (sc *SecureConn) PeerStaticKey() []byte {
	return sc.peerID
}

// LocalAddr returns the local network address.
func (sc *SecureConn) LocalAddr() net.Addr {
	return sc.raw.LocalAddr()
}

// RemoteAddr returns the remote network address.
func (sc *SecureConn) RemoteAddr() net.Addr {
	return sc.raw.RemoteAddr()
}

// SetDeadline sets the deadline on the underlying connection.
func (sc *SecureConn) SetDeadline(t time.Time) error {
	return sc.raw.SetDeadline(t)
}

// SetReadDeadline sets the read deadline on the underlying connection.
func (sc *SecureConn) SetReadDeadline(t time.Time) error {
	return sc.raw.SetReadDeadline(t)
}

// SetWriteDeadline sets the write deadline on the underlying connection.
func (sc *SecureConn) SetWriteDeadline(t time.Time) error {
	return sc.raw.SetWriteDeadline(t)
}

// UpgradeToSecure performs a Noise handshake over an existing net.Conn
// and returns a SecureConn with encrypted read/write.
func UpgradeToSecure(ctx context.Context, conn net.Conn, cfg Config) (*SecureConn, error) {
	deadline := time.Now().Add(HandshakeTimeout)
	if dl, ok := ctx.Deadline(); ok && dl.Before(deadline) {
		deadline = dl
	}
	conn.SetDeadline(deadline)
	defer conn.SetDeadline(time.Time{}) // Clear after handshake

	hs, err := NewState(cfg)
	if err != nil {
		return nil, fmt.Errorf("create noise handshake state: %w", err)
	}

	var sendCS, recvCS *noise.CipherState

	if cfg.Initiator {
		sendCS, recvCS, err = performInitiatorHandshake(conn, hs)
	} else {
		recvCS, sendCS, err = performResponderHandshake(conn, hs)
	}
	if err != nil {
		return nil, err
	}

	peerStatic := hs.PeerStatic()
	log.Printf("[airbridge-noise] handshake complete: peer=%x initiator=%v",
		peerStatic[:min(8, len(peerStatic))], cfg.Initiator)

	return &SecureConn{
		raw:    conn,
		send:   sendCS,
		recv:   recvCS,
		peerID: peerStatic,
	}, nil
}

// performInitiatorHandshake drives the Noise handshake from the initiator side.
func performInitiatorHandshake(conn net.Conn, hs *noise.HandshakeState) (*noise.CipherState, *noise.CipherState, error) {
	// Round 1: Initiator → Responder (e, es or e, s, ...)
	msg1, cs1, cs2, err := hs.WriteMessage(nil, nil)
	if err != nil {
		return nil, nil, fmt.Errorf("write handshake msg1: %w", err)
	}
	if err := writeFrame(conn, msg1); err != nil {
		return nil, nil, err
	}

	if cs1 != nil && cs2 != nil {
		return cs1, cs2, nil // IK pattern: 1-RTT
	}

	// Round 2: Responder → Initiator
	msg2, err := readFrame(conn)
	if err != nil {
		return nil, nil, err
	}
	_, cs1, cs2, err = hs.ReadMessage(nil, msg2)
	if err != nil {
		return nil, nil, fmt.Errorf("read handshake msg2: %w", err)
	}

	if cs1 != nil && cs2 != nil {
		return cs1, cs2, nil
	}

	// Round 3: Initiator → Responder (XX pattern needs 3 messages)
	msg3, cs1, cs2, err := hs.WriteMessage(nil, nil)
	if err != nil {
		return nil, nil, fmt.Errorf("write handshake msg3: %w", err)
	}
	if err := writeFrame(conn, msg3); err != nil {
		return nil, nil, err
	}

	return cs1, cs2, nil
}

// performResponderHandshake drives the Noise handshake from the responder side.
func performResponderHandshake(conn net.Conn, hs *noise.HandshakeState) (*noise.CipherState, *noise.CipherState, error) {
	// Round 1: Read Initiator's first message
	msg1, err := readFrame(conn)
	if err != nil {
		return nil, nil, err
	}
	_, cs1, cs2, err := hs.ReadMessage(nil, msg1)
	if err != nil {
		return nil, nil, fmt.Errorf("read handshake msg1: %w", err)
	}

	if cs1 != nil && cs2 != nil {
		return cs1, cs2, nil
	}

	// Round 2: Responder → Initiator
	msg2, cs1, cs2, err := hs.WriteMessage(nil, nil)
	if err != nil {
		return nil, nil, fmt.Errorf("write handshake msg2: %w", err)
	}
	if err := writeFrame(conn, msg2); err != nil {
		return nil, nil, err
	}

	if cs1 != nil && cs2 != nil {
		return cs1, cs2, nil
	}

	// Round 3: Read Initiator's third message (XX pattern)
	msg3, err := readFrame(conn)
	if err != nil {
		return nil, nil, err
	}
	_, cs1, cs2, err = hs.ReadMessage(nil, msg3)
	if err != nil {
		return nil, nil, fmt.Errorf("read handshake msg3: %w", err)
	}

	return cs1, cs2, nil
}

// writeFrame writes a length-prefixed frame to the connection.
func writeFrame(conn net.Conn, data []byte) error {
	lenBuf := make([]byte, 2)
	binary.BigEndian.PutUint16(lenBuf, uint16(len(data)))
	if _, err := conn.Write(lenBuf); err != nil {
		return fmt.Errorf("write frame length: %w", err)
	}
	if _, err := conn.Write(data); err != nil {
		return fmt.Errorf("write frame data: %w", err)
	}
	return nil
}

// readFrame reads a length-prefixed frame from the connection.
func readFrame(conn net.Conn) ([]byte, error) {
	lenBuf := make([]byte, 2)
	if _, err := io.ReadFull(conn, lenBuf); err != nil {
		return nil, fmt.Errorf("read frame length: %w", err)
	}
	frameLen := int(binary.BigEndian.Uint16(lenBuf))
	if frameLen <= 0 || frameLen > MaxHandshakePayload {
		return nil, fmt.Errorf("invalid frame length: %d", frameLen)
	}
	data := make([]byte, frameLen)
	if _, err := io.ReadFull(conn, data); err != nil {
		return nil, fmt.Errorf("read frame data: %w", err)
	}
	return data, nil
}

// WrapListener returns a net.Listener that upgrades all accepted connections
// with a Noise handshake (responder side).
func WrapListener(inner net.Listener, staticKey noise.DHKey, aead protocol.AEADSuite) *SecureListener {
	return &SecureListener{
		inner:     inner,
		staticKey: staticKey,
		aead:      aead,
	}
}

// SecureListener wraps a net.Listener with Noise handshake on accept.
type SecureListener struct {
	inner     net.Listener
	staticKey noise.DHKey
	aead      protocol.AEADSuite
}

// Accept waits for and returns the next connection, upgraded with Noise.
func (sl *SecureListener) Accept() (net.Conn, error) {
	conn, err := sl.inner.Accept()
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), HandshakeTimeout)
	defer cancel()

	secure, err := UpgradeToSecure(ctx, conn, Config{
		Initiator:     false,
		Pattern:       protocol.NoiseXX,
		AEAD:          sl.aead,
		StaticKeypair: sl.staticKey,
	})
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("noise handshake failed: %w", err)
	}

	return secure, nil
}

// Close closes the underlying listener.
func (sl *SecureListener) Close() error {
	return sl.inner.Close()
}

// Addr returns the listener's network address.
func (sl *SecureListener) Addr() net.Addr {
	return sl.inner.Addr()
}

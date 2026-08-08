package mesh

import (
	"context"
	"encoding/binary"
	"errors"
	"fmt"
	"log"
	"net"
	"sync"
	"time"
)

// NAT traversal constants.
const (
	// STUN message types (RFC 5389)
	stunBindingRequest    = 0x0001
	stunBindingResponse   = 0x0101
	stunMagicCookie       = 0x2112A442

	// STUN attributes
	stunAttrMappedAddress    = 0x0001
	stunAttrXorMappedAddress = 0x0020

	// Default STUN servers
	DefaultSTUNServer1 = "stun.l.google.com:19302"
	DefaultSTUNServer2 = "stun1.l.google.com:19302"
	DefaultSTUNServer3 = "stun.cloudflare.com:3478"
)

// NATType represents the detected NAT type.
type NATType int

const (
	NATUnknown NATType = iota
	NATNone            // No NAT (public IP)
	NATFull            // Full Cone NAT
	NATRestricted      // Restricted Cone NAT
	NATPortRestricted  // Port-Restricted Cone NAT
	NATSymmetric       // Symmetric NAT (hardest to traverse)
)

func (n NATType) String() string {
	switch n {
	case NATNone:
		return "No NAT (Public IP)"
	case NATFull:
		return "Full Cone NAT"
	case NATRestricted:
		return "Restricted Cone NAT"
	case NATPortRestricted:
		return "Port-Restricted Cone NAT"
	case NATSymmetric:
		return "Symmetric NAT"
	default:
		return "Unknown"
	}
}

// NATTraversalResult contains the result of NAT detection and hole punching.
type NATTraversalResult struct {
	NATType       NATType
	PublicAddr    string // External IP:port as seen by STUN server
	LocalAddr     string // Local IP:port
	MappingStable bool   // True if NAT mapping is consistent across servers
}

// STUNClient implements STUN (RFC 5389) binding requests for NAT traversal.
type STUNClient struct {
	servers []string
	timeout time.Duration
	mu      sync.Mutex
}

// NewSTUNClient creates a STUN client with the given server list.
func NewSTUNClient(servers []string) *STUNClient {
	if len(servers) == 0 {
		servers = []string{DefaultSTUNServer1, DefaultSTUNServer2, DefaultSTUNServer3}
	}
	return &STUNClient{
		servers: servers,
		timeout: 5 * time.Second,
	}
}

// DiscoverPublicAddress sends a STUN Binding Request and returns the reflexive address.
func (c *STUNClient) DiscoverPublicAddress(ctx context.Context) (*NATTraversalResult, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	result := &NATTraversalResult{NATType: NATUnknown}

	// Try each STUN server
	var firstAddr string
	var lastConn *net.UDPConn

	for i, server := range c.servers {
		addr, conn, err := c.sendBindingRequest(ctx, server)
		if err != nil {
			log.Printf("[airbridge-nat] STUN server %s failed: %v", server, err)
			continue
		}

		if lastConn != nil {
			lastConn.Close()
		}
		lastConn = conn

		if i == 0 {
			firstAddr = addr
			result.PublicAddr = addr
			result.LocalAddr = conn.LocalAddr().String()
		} else {
			// Compare mappings across servers to detect NAT type
			if addr != firstAddr {
				result.NATType = NATSymmetric
				result.MappingStable = false
			} else {
				result.MappingStable = true
			}
		}
	}

	if lastConn != nil {
		lastConn.Close()
	}

	if result.PublicAddr == "" {
		return nil, errors.New("all STUN servers unreachable")
	}

	// Determine NAT type
	if result.NATType != NATSymmetric {
		if result.PublicAddr == result.LocalAddr {
			result.NATType = NATNone
		} else if result.MappingStable {
			result.NATType = NATFull // Conservative: could be restricted
		}
	}

	log.Printf("[airbridge-nat] NAT detection: type=%s public=%s local=%s stable=%v",
		result.NATType, result.PublicAddr, result.LocalAddr, result.MappingStable)

	return result, nil
}

// sendBindingRequest sends a STUN Binding Request to the given server.
func (c *STUNClient) sendBindingRequest(ctx context.Context, server string) (string, *net.UDPConn, error) {
	serverAddr, err := net.ResolveUDPAddr("udp", server)
	if err != nil {
		return "", nil, fmt.Errorf("resolve STUN server: %w", err)
	}

	conn, err := net.DialUDP("udp", nil, serverAddr)
	if err != nil {
		return "", nil, fmt.Errorf("dial STUN server: %w", err)
	}

	// Build STUN Binding Request
	txID := make([]byte, 12) // Transaction ID
	copy(txID, []byte("airbridge5gxx")) // Deterministic for debugging

	msg := make([]byte, 20)
	binary.BigEndian.PutUint16(msg[0:2], stunBindingRequest)
	binary.BigEndian.PutUint16(msg[2:4], 0) // Message length (no attributes)
	binary.BigEndian.PutUint32(msg[4:8], stunMagicCookie)
	copy(msg[8:20], txID)

	// Set deadline
	deadline := time.Now().Add(c.timeout)
	if dl, ok := ctx.Deadline(); ok && dl.Before(deadline) {
		deadline = dl
	}
	conn.SetDeadline(deadline)

	// Send request
	if _, err := conn.Write(msg); err != nil {
		conn.Close()
		return "", nil, fmt.Errorf("send STUN request: %w", err)
	}

	// Read response
	buf := make([]byte, 1024)
	n, err := conn.Read(buf)
	if err != nil {
		conn.Close()
		return "", nil, fmt.Errorf("read STUN response: %w", err)
	}

	if n < 20 {
		conn.Close()
		return "", nil, errors.New("STUN response too short")
	}

	// Verify response type
	msgType := binary.BigEndian.Uint16(buf[0:2])
	if msgType != stunBindingResponse {
		conn.Close()
		return "", nil, fmt.Errorf("unexpected STUN message type: 0x%04x", msgType)
	}

	// Parse XOR-MAPPED-ADDRESS or MAPPED-ADDRESS
	addr, err := c.parseAddress(buf[:n])
	if err != nil {
		conn.Close()
		return "", nil, err
	}

	return addr, conn, nil
}

// parseAddress extracts the mapped address from a STUN response.
func (c *STUNClient) parseAddress(msg []byte) (string, error) {
	if len(msg) < 20 {
		return "", errors.New("message too short")
	}

	msgLen := binary.BigEndian.Uint16(msg[2:4])
	if int(msgLen)+20 > len(msg) {
		return "", errors.New("message length mismatch")
	}

	// Parse attributes
	offset := 20
	for offset < int(msgLen)+20 {
		if offset+4 > len(msg) {
			break
		}

		attrType := binary.BigEndian.Uint16(msg[offset : offset+2])
		attrLen := binary.BigEndian.Uint16(msg[offset+2 : offset+4])
		offset += 4

		if offset+int(attrLen) > len(msg) {
			break
		}

		attrData := msg[offset : offset+int(attrLen)]

		switch attrType {
		case stunAttrXorMappedAddress:
			return c.parseXorMappedAddress(attrData, msg[4:8])
		case stunAttrMappedAddress:
			return c.parseMappedAddress(attrData)
		}

		// Pad to 4-byte boundary
		offset += int(attrLen)
		if offset%4 != 0 {
			offset += 4 - (offset % 4)
		}
	}

	return "", errors.New("no mapped address in STUN response")
}

// parseXorMappedAddress decodes XOR-MAPPED-ADDRESS (RFC 5389 Section 15.2).
func (c *STUNClient) parseXorMappedAddress(data []byte, magicCookie []byte) (string, error) {
	if len(data) < 8 {
		return "", errors.New("XOR-MAPPED-ADDRESS too short")
	}

	family := data[1]
	xorPort := binary.BigEndian.Uint16(data[2:4])
	port := xorPort ^ uint16(stunMagicCookie>>16)

	if family == 0x01 { // IPv4
		ip := make(net.IP, 4)
		for i := 0; i < 4; i++ {
			ip[i] = data[4+i] ^ magicCookie[i]
		}
		return fmt.Sprintf("%s:%d", ip.String(), port), nil
	}

	return "", fmt.Errorf("unsupported address family: %d", family)
}

// parseMappedAddress decodes MAPPED-ADDRESS (RFC 5389 Section 15.1).
func (c *STUNClient) parseMappedAddress(data []byte) (string, error) {
	if len(data) < 8 {
		return "", errors.New("MAPPED-ADDRESS too short")
	}

	family := data[1]
	port := binary.BigEndian.Uint16(data[2:4])

	if family == 0x01 { // IPv4
		ip := net.IP(data[4:8])
		return fmt.Sprintf("%s:%d", ip.String(), port), nil
	}

	return "", fmt.Errorf("unsupported address family: %d", family)
}

// HolePunch attempts UDP hole punching to establish a direct connection
// between two peers behind NAT.
func (c *STUNClient) HolePunch(ctx context.Context, localPort int, peerAddr string) (*net.UDPConn, error) {
	peerUDP, err := net.ResolveUDPAddr("udp", peerAddr)
	if err != nil {
		return nil, fmt.Errorf("resolve peer address: %w", err)
	}

	localUDP := &net.UDPAddr{Port: localPort}
	conn, err := net.ListenUDP("udp", localUDP)
	if err != nil {
		return nil, fmt.Errorf("listen for hole punch: %w", err)
	}

	// Send punch packets (creates NAT mapping)
	punchMsg := []byte("AIRBRIDGE_PUNCH")
	for i := 0; i < 5; i++ {
		if ctx.Err() != nil {
			conn.Close()
			return nil, ctx.Err()
		}
		_, _ = conn.WriteToUDP(punchMsg, peerUDP)
		time.Sleep(200 * time.Millisecond)
	}

	// Wait for response from peer
	conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	buf := make([]byte, 1024)
	n, remoteAddr, err := conn.ReadFromUDP(buf)
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("hole punch timeout: %w", err)
	}

	log.Printf("[airbridge-nat] hole punch success: %s → %s (%d bytes)", localUDP, remoteAddr, n)
	conn.SetReadDeadline(time.Time{}) // Clear deadline

	return conn, nil
}

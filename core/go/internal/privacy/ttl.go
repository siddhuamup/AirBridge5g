// Package privacy implements the AirBridge 5G privacy preservation engine
// including TTL normalization, DPI resilience, and User-Agent harmonization.
package privacy

import (
	"encoding/binary"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
)

// Common TTL values by operating system.
const (
	TTLLinux   = 64
	TTLWindows = 128
	TTLMacOS   = 64
	TTLiOS     = 64
	TTLAndroid = 64

	// DefaultTargetTTL normalizes all traffic to look like mobile-originated.
	DefaultTargetTTL = 64

	// IP protocol version identifiers.
	ipv4Version = 4
	ipv6Version = 6

	// IPv4 header field offsets.
	ipv4VersionOffset  = 0
	ipv4TTLOffset      = 8
	ipv4ChecksumOffset = 10
	ipv4MinHeaderLen   = 20

	// IPv6 header field offsets.
	ipv6VersionOffset  = 0
	ipv6HopLimitOffset = 7
	ipv6MinHeaderLen   = 40
)

// Errors returned by the TTL normalizer.
var (
	ErrPacketTooShort = errors.New("packet too short for IP header")
	ErrNotIPPacket    = errors.New("not an IP packet")
	ErrInvalidTTL     = errors.New("target TTL must be 1-255")
)

// TTLStats tracks normalization statistics.
type TTLStats struct {
	PacketsProcessed atomic.Int64
	PacketsModified  atomic.Int64
	IPv4Packets      atomic.Int64
	IPv6Packets      atomic.Int64
	OriginalTTLs     sync.Map // maps original TTL (int) → count (*atomic.Int64)
}

// TTLStatsSnapshot is an immutable point-in-time view of TTL statistics.
type TTLStatsSnapshot struct {
	PacketsProcessed int64
	PacketsModified  int64
	IPv4Packets      int64
	IPv6Packets      int64
	OriginalTTLHist  map[int]int64
}

// Snapshot returns a point-in-time copy of TTL stats.
func (s *TTLStats) Snapshot() TTLStatsSnapshot {
	hist := make(map[int]int64)
	s.OriginalTTLs.Range(func(key, value any) bool {
		ttl := key.(int)
		counter := value.(*atomic.Int64)
		hist[ttl] = counter.Load()
		return true
	})
	return TTLStatsSnapshot{
		PacketsProcessed: s.PacketsProcessed.Load(),
		PacketsModified:  s.PacketsModified.Load(),
		IPv4Packets:      s.IPv4Packets.Load(),
		IPv6Packets:      s.IPv6Packets.Load(),
		OriginalTTLHist:  hist,
	}
}

func (s *TTLStats) recordOriginalTTL(ttl int) {
	val, _ := s.OriginalTTLs.LoadOrStore(ttl, &atomic.Int64{})
	val.(*atomic.Int64).Add(1)
}

// TTLNormalizerConfig configures the TTL normalizer.
type TTLNormalizerConfig struct {
	TargetTTL byte // Target TTL value (default: 64)
	Enabled   bool // Whether normalization is active
}

// DefaultTTLConfig returns sensible defaults for mobile traffic masking.
func DefaultTTLConfig() TTLNormalizerConfig {
	return TTLNormalizerConfig{
		TargetTTL: DefaultTargetTTL,
		Enabled:   true,
	}
}

// TTLNormalizer rewrites IP TTL/Hop Limit values to prevent OS fingerprinting.
type TTLNormalizer struct {
	cfg   TTLNormalizerConfig
	stats TTLStats
}

// NewTTLNormalizer creates a new TTL normalizer with the given config.
func NewTTLNormalizer(cfg TTLNormalizerConfig) (*TTLNormalizer, error) {
	if cfg.TargetTTL == 0 {
		cfg.TargetTTL = DefaultTargetTTL
	}
	return &TTLNormalizer{cfg: cfg}, nil
}

// GetStats returns current normalization statistics.
func (n *TTLNormalizer) GetStats() TTLStatsSnapshot {
	return n.stats.Snapshot()
}

// IsEnabled returns true if TTL normalization is active.
func (n *TTLNormalizer) IsEnabled() bool {
	return n.cfg.Enabled
}

// SetEnabled dynamically enables or disables TTL normalization.
func (n *TTLNormalizer) SetEnabled(enabled bool) {
	n.cfg.Enabled = enabled
}

// NormalizePacket rewrites the TTL/Hop Limit in an IP packet.
// The packet is modified in-place. Returns the original TTL for logging.
func (n *TTLNormalizer) NormalizePacket(packet []byte) (originalTTL byte, err error) {
	if !n.cfg.Enabled {
		return 0, nil
	}

	n.stats.PacketsProcessed.Add(1)

	if len(packet) < 1 {
		return 0, ErrPacketTooShort
	}

	version := (packet[ipv4VersionOffset] >> 4) & 0x0F

	switch version {
	case ipv4Version:
		return n.normalizeIPv4(packet)
	case ipv6Version:
		return n.normalizeIPv6(packet)
	default:
		return 0, fmt.Errorf("%w: version %d", ErrNotIPPacket, version)
	}
}

// normalizeIPv4 rewrites the TTL field in an IPv4 packet and recalculates
// the header checksum.
func (n *TTLNormalizer) normalizeIPv4(packet []byte) (byte, error) {
	if len(packet) < ipv4MinHeaderLen {
		return 0, fmt.Errorf("%w: need %d bytes, got %d", ErrPacketTooShort, ipv4MinHeaderLen, len(packet))
	}

	n.stats.IPv4Packets.Add(1)

	// Extract IHL (Internet Header Length) to determine header size
	ihl := int(packet[0]&0x0F) * 4
	if ihl < ipv4MinHeaderLen || len(packet) < ihl {
		return 0, fmt.Errorf("%w: invalid IHL %d", ErrPacketTooShort, ihl)
	}

	originalTTL := packet[ipv4TTLOffset]
	n.stats.recordOriginalTTL(int(originalTTL))

	if originalTTL == n.cfg.TargetTTL {
		return originalTTL, nil // Already at target, no change needed
	}

	// Rewrite TTL
	packet[ipv4TTLOffset] = n.cfg.TargetTTL
	n.stats.PacketsModified.Add(1)

	// Recalculate IPv4 header checksum
	recalcIPv4Checksum(packet[:ihl])

	return originalTTL, nil
}

// normalizeIPv6 rewrites the Hop Limit field in an IPv6 packet.
// IPv6 has no header checksum, so no recalculation is needed.
func (n *TTLNormalizer) normalizeIPv6(packet []byte) (byte, error) {
	if len(packet) < ipv6MinHeaderLen {
		return 0, fmt.Errorf("%w: need %d bytes, got %d", ErrPacketTooShort, ipv6MinHeaderLen, len(packet))
	}

	n.stats.IPv6Packets.Add(1)

	originalHopLimit := packet[ipv6HopLimitOffset]
	n.stats.recordOriginalTTL(int(originalHopLimit))

	if originalHopLimit == n.cfg.TargetTTL {
		return originalHopLimit, nil
	}

	packet[ipv6HopLimitOffset] = n.cfg.TargetTTL
	n.stats.PacketsModified.Add(1)

	return originalHopLimit, nil
}

// recalcIPv4Checksum recalculates the IPv4 header checksum in-place.
func recalcIPv4Checksum(header []byte) {
	// Zero out existing checksum
	header[ipv4ChecksumOffset] = 0
	header[ipv4ChecksumOffset+1] = 0

	// Calculate one's complement sum of all 16-bit words
	var sum uint32
	for i := 0; i < len(header)-1; i += 2 {
		sum += uint32(binary.BigEndian.Uint16(header[i : i+2]))
	}
	// Handle odd-length headers (shouldn't happen for valid IPv4)
	if len(header)%2 != 0 {
		sum += uint32(header[len(header)-1]) << 8
	}

	// Fold 32-bit sum to 16-bit
	for sum > 0xFFFF {
		sum = (sum >> 16) + (sum & 0xFFFF)
	}

	// One's complement
	checksum := ^uint16(sum)
	binary.BigEndian.PutUint16(header[ipv4ChecksumOffset:], checksum)
}

// DetectOS attempts to identify the source OS based on initial TTL value.
func DetectOS(ttl byte) string {
	switch {
	case ttl <= 64 && ttl > 32:
		return "Linux/macOS/iOS/Android"
	case ttl <= 128 && ttl > 64:
		return "Windows"
	case ttl <= 255 && ttl > 128:
		return "Solaris/Network Equipment"
	default:
		return "Unknown"
	}
}

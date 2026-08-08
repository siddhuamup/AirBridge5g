package privacy

import (
	"encoding/binary"
	"testing"
)

// buildIPv4Packet creates a minimal valid IPv4 packet for testing.
func buildIPv4Packet(ttl byte) []byte {
	packet := make([]byte, 20)                  // Minimum IPv4 header
	packet[0] = 0x45                            // Version=4, IHL=5 (20 bytes)
	packet[1] = 0x00                            // DSCP + ECN
	binary.BigEndian.PutUint16(packet[2:4], 20) // Total length
	packet[8] = ttl                             // TTL
	packet[9] = 0x06                            // Protocol: TCP
	// Checksum at bytes 10-11 (set to 0, recalculated)
	// Source IP: 192.168.1.1
	packet[12], packet[13], packet[14], packet[15] = 192, 168, 1, 1
	// Dest IP: 8.8.8.8
	packet[16], packet[17], packet[18], packet[19] = 8, 8, 8, 8
	recalcIPv4Checksum(packet)
	return packet
}

// buildIPv6Packet creates a minimal valid IPv6 packet for testing.
func buildIPv6Packet(hopLimit byte) []byte {
	packet := make([]byte, 40)                 // Minimum IPv6 header
	packet[0] = 0x60                           // Version=6
	packet[7] = hopLimit                       // Hop Limit
	binary.BigEndian.PutUint16(packet[4:6], 0) // Payload length
	packet[6] = 0x06                           // Next Header: TCP
	return packet
}

func TestNewTTLNormalizer(t *testing.T) {
	cfg := DefaultTTLConfig()
	norm, err := NewTTLNormalizer(cfg)
	if err != nil {
		t.Fatalf("NewTTLNormalizer: %v", err)
	}
	if norm == nil {
		t.Fatal("normalizer is nil")
	}
}

func TestTTLNormalizerDefaultTarget(t *testing.T) {
	norm, _ := NewTTLNormalizer(TTLNormalizerConfig{TargetTTL: 0, Enabled: true})
	if norm.cfg.TargetTTL != DefaultTargetTTL {
		t.Errorf("default TTL = %d, want %d", norm.cfg.TargetTTL, DefaultTargetTTL)
	}
}

func TestNormalizeIPv4WindowsTTL(t *testing.T) {
	norm, _ := NewTTLNormalizer(DefaultTTLConfig())
	packet := buildIPv4Packet(128) // Windows TTL

	original, err := norm.NormalizePacket(packet)
	if err != nil {
		t.Fatalf("normalize: %v", err)
	}

	if original != 128 {
		t.Errorf("original TTL = %d, want 128", original)
	}
	if packet[ipv4TTLOffset] != 64 {
		t.Errorf("normalized TTL = %d, want 64", packet[ipv4TTLOffset])
	}

	// Verify checksum is valid
	verifyIPv4Checksum(t, packet[:20])
}

func TestNormalizeIPv4AlreadyTarget(t *testing.T) {
	norm, _ := NewTTLNormalizer(DefaultTTLConfig())
	packet := buildIPv4Packet(64) // Already at target

	original, err := norm.NormalizePacket(packet)
	if err != nil {
		t.Fatalf("normalize: %v", err)
	}

	if original != 64 {
		t.Errorf("original TTL = %d, want 64", original)
	}

	stats := norm.GetStats()
	if stats.PacketsModified != 0 {
		t.Errorf("should not modify already-target packet, modified=%d", stats.PacketsModified)
	}
}

func TestNormalizeIPv6(t *testing.T) {
	norm, _ := NewTTLNormalizer(DefaultTTLConfig())
	packet := buildIPv6Packet(128) // Windows hop limit

	original, err := norm.NormalizePacket(packet)
	if err != nil {
		t.Fatalf("normalize: %v", err)
	}

	if original != 128 {
		t.Errorf("original hop limit = %d, want 128", original)
	}
	if packet[ipv6HopLimitOffset] != 64 {
		t.Errorf("normalized hop limit = %d, want 64", packet[ipv6HopLimitOffset])
	}
}

func TestNormalizeDisabled(t *testing.T) {
	norm, _ := NewTTLNormalizer(TTLNormalizerConfig{TargetTTL: 64, Enabled: false})
	packet := buildIPv4Packet(128)

	_, err := norm.NormalizePacket(packet)
	if err != nil {
		t.Fatalf("normalize disabled: %v", err)
	}
	if packet[ipv4TTLOffset] != 128 {
		t.Error("should not modify packet when disabled")
	}
}

func TestNormalizePacketTooShort(t *testing.T) {
	norm, _ := NewTTLNormalizer(DefaultTTLConfig())

	_, err := norm.NormalizePacket([]byte{})
	if err != ErrPacketTooShort {
		t.Errorf("expected ErrPacketTooShort, got %v", err)
	}

	_, err = norm.NormalizePacket([]byte{0x45, 0x00}) // Too short for IPv4
	if err == nil {
		t.Error("expected error for short IPv4 packet")
	}
}

func TestNormalizeInvalidVersion(t *testing.T) {
	norm, _ := NewTTLNormalizer(DefaultTTLConfig())
	packet := []byte{0x30, 0x00} // Version 3 (invalid)

	_, err := norm.NormalizePacket(packet)
	if err == nil {
		t.Error("expected error for invalid IP version")
	}
}

func TestTTLStats(t *testing.T) {
	norm, _ := NewTTLNormalizer(DefaultTTLConfig())

	// Process a mix of packets
	for i := 0; i < 5; i++ {
		packet := buildIPv4Packet(128)
		norm.NormalizePacket(packet)
	}
	for i := 0; i < 3; i++ {
		packet := buildIPv6Packet(128)
		norm.NormalizePacket(packet)
	}
	// One already at target
	packet := buildIPv4Packet(64)
	norm.NormalizePacket(packet)

	stats := norm.GetStats()
	if stats.PacketsProcessed != 9 {
		t.Errorf("PacketsProcessed = %d, want 9", stats.PacketsProcessed)
	}
	if stats.PacketsModified != 8 {
		t.Errorf("PacketsModified = %d, want 8", stats.PacketsModified)
	}
	if stats.IPv4Packets != 6 {
		t.Errorf("IPv4Packets = %d, want 6", stats.IPv4Packets)
	}
	if stats.IPv6Packets != 3 {
		t.Errorf("IPv6Packets = %d, want 3", stats.IPv6Packets)
	}
	if count, ok := stats.OriginalTTLHist[128]; !ok || count != 8 {
		t.Errorf("TTL histogram[128] = %d, want 8", count)
	}
}

func TestDetectOS(t *testing.T) {
	tests := []struct {
		ttl      byte
		expected string
	}{
		{64, "Linux/macOS/iOS/Android"},
		{128, "Windows"},
		{255, "Solaris/Network Equipment"},
		{1, "Unknown"},
	}

	for _, tt := range tests {
		result := DetectOS(tt.ttl)
		if result != tt.expected {
			t.Errorf("DetectOS(%d) = %q, want %q", tt.ttl, result, tt.expected)
		}
	}
}

// verifyIPv4Checksum verifies that the IPv4 header checksum is correct.
func verifyIPv4Checksum(t *testing.T, header []byte) {
	t.Helper()
	var sum uint32
	for i := 0; i < len(header)-1; i += 2 {
		sum += uint32(binary.BigEndian.Uint16(header[i : i+2]))
	}
	for sum > 0xFFFF {
		sum = (sum >> 16) + (sum & 0xFFFF)
	}
	if uint16(sum) != 0xFFFF {
		t.Errorf("invalid checksum: sum=0x%04X, want 0xFFFF", uint16(sum))
	}
}

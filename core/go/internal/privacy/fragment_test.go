package privacy

import (
	"bytes"
	"testing"
)

func TestNewFragmenter(t *testing.T) {
	cfg := DefaultFragmenterConfig()
	f, err := NewFragmenter(cfg)
	if err != nil {
		t.Fatalf("NewFragmenter: %v", err)
	}
	if f == nil {
		t.Fatal("fragmenter is nil")
	}
}

func TestFragmenterTooSmall(t *testing.T) {
	cfg := FragmenterConfig{
		MaxFragmentLen: 10, // Below minimum
		Enabled:        true,
	}
	_, err := NewFragmenter(cfg)
	if err == nil {
		t.Error("expected error for fragment size below minimum")
	}
}

func TestFragmentFixed(t *testing.T) {
	cfg := FragmenterConfig{
		Strategy:       StrategyFixed,
		MaxFragmentLen: 100,
		Enabled:        true,
	}
	f, _ := NewFragmenter(cfg)

	payload := make([]byte, 350)
	for i := range payload {
		payload[i] = byte(i % 256)
	}

	fragments, err := f.Fragment(payload)
	if err != nil {
		t.Fatalf("Fragment: %v", err)
	}

	// Should produce 4 fragments: 100 + 100 + 100 + 50
	if len(fragments) != 4 {
		t.Errorf("expected 4 fragments, got %d", len(fragments))
	}

	// Verify reassembly
	reassembled := make([]byte, 0, len(payload))
	for _, frag := range fragments {
		reassembled = append(reassembled, frag...)
	}
	if !bytes.Equal(reassembled, payload) {
		t.Error("reassembled data does not match original")
	}

	// Verify stats
	stats := f.GetStats()
	if stats.PacketsFragmented != 1 {
		t.Errorf("PacketsFragmented = %d, want 1", stats.PacketsFragmented)
	}
	if stats.FragmentsCreated != 4 {
		t.Errorf("FragmentsCreated = %d, want 4", stats.FragmentsCreated)
	}
}

func TestFragmentRandom(t *testing.T) {
	cfg := FragmenterConfig{
		Strategy:       StrategyRandom,
		MaxFragmentLen: 200,
		MinFragmentLen: 64,
		Enabled:        true,
	}
	f, _ := NewFragmenter(cfg)

	payload := make([]byte, 1000)
	for i := range payload {
		payload[i] = byte(i % 256)
	}

	fragments, err := f.Fragment(payload)
	if err != nil {
		t.Fatalf("Fragment: %v", err)
	}

	if len(fragments) < 2 {
		t.Error("random fragmentation should produce multiple fragments")
	}

	// Verify reassembly
	reassembled := make([]byte, 0, len(payload))
	for _, frag := range fragments {
		reassembled = append(reassembled, frag...)
	}
	if !bytes.Equal(reassembled, payload) {
		t.Error("reassembled data does not match original")
	}
}

func TestFragmentDisabled(t *testing.T) {
	cfg := FragmenterConfig{
		Strategy:       StrategyFixed,
		MaxFragmentLen: 100,
		Enabled:        false,
	}
	f, _ := NewFragmenter(cfg)

	payload := []byte("hello world")
	fragments, err := f.Fragment(payload)
	if err != nil {
		t.Fatalf("Fragment: %v", err)
	}

	if len(fragments) != 1 {
		t.Errorf("disabled fragmenter should return 1 fragment, got %d", len(fragments))
	}
}

func TestFragmentEmpty(t *testing.T) {
	f, _ := NewFragmenter(DefaultFragmenterConfig())
	_, err := f.Fragment([]byte{})
	if err != ErrEmptyPayload {
		t.Errorf("expected ErrEmptyPayload, got %v", err)
	}
}

func TestFragmentSmallPayload(t *testing.T) {
	cfg := FragmenterConfig{
		Strategy:       StrategyFixed,
		MaxFragmentLen: 1024,
		Enabled:        true,
	}
	f, _ := NewFragmenter(cfg)

	payload := []byte("small")
	fragments, err := f.Fragment(payload)
	if err != nil {
		t.Fatalf("Fragment: %v", err)
	}

	if len(fragments) != 1 {
		t.Errorf("small payload should produce 1 fragment, got %d", len(fragments))
	}
	if !bytes.Equal(fragments[0], payload) {
		t.Error("single fragment should equal original payload")
	}
}

func TestFragmentTLSRecord(t *testing.T) {
	cfg := FragmenterConfig{
		Strategy:       StrategyTLSSplit,
		MaxFragmentLen: 256,
		MinFragmentLen: 64,
		Enabled:        true,
	}
	f, _ := NewFragmenter(cfg)

	// Build a fake TLS Application Data record
	recordPayload := make([]byte, 500)
	for i := range recordPayload {
		recordPayload[i] = byte(i % 256)
	}

	tlsRecord := make([]byte, 5+len(recordPayload))
	tlsRecord[0] = TLSContentTypeAppData // Content type
	tlsRecord[1] = 0x03                  // TLS 1.2 major
	tlsRecord[2] = 0x03                  // TLS 1.2 minor
	tlsRecord[3] = byte(len(recordPayload) >> 8)
	tlsRecord[4] = byte(len(recordPayload) & 0xFF)
	copy(tlsRecord[5:], recordPayload)

	fragments, err := f.Fragment(tlsRecord)
	if err != nil {
		t.Fatalf("Fragment TLS: %v", err)
	}

	if len(fragments) < 2 {
		t.Error("TLS record split should produce multiple fragments")
	}

	// Each fragment should be a valid TLS record
	for i, frag := range fragments {
		if len(frag) < TLSRecordHeaderLen {
			t.Errorf("fragment %d too short: %d bytes", i, len(frag))
			continue
		}
		if frag[0] != TLSContentTypeAppData {
			t.Errorf("fragment %d: content type = 0x%02X, want 0x%02X", i, frag[0], TLSContentTypeAppData)
		}
	}

	stats := f.GetStats()
	if stats.TLSRecordsSplit != 1 {
		t.Errorf("TLSRecordsSplit = %d, want 1", stats.TLSRecordsSplit)
	}
}

func TestFragmentWriterRoundTrip(t *testing.T) {
	f, _ := NewFragmenter(FragmenterConfig{
		Strategy:       StrategyFixed,
		MaxFragmentLen: 64,
		MinFragmentLen: 64,
		Enabled:        true,
	})

	var buf bytes.Buffer
	writer := NewFragmentWriter(&buf, f)

	data := []byte("The quick brown fox jumps over the lazy dog. AirBridge 5G testing!")
	n, err := writer.Write(data)
	if err != nil {
		t.Fatalf("FragmentWriter.Write: %v", err)
	}
	if n != len(data) {
		t.Errorf("wrote %d bytes, want %d", n, len(data))
	}

	// The buffer should contain the same data (just written in fragments)
	if !bytes.Equal(buf.Bytes(), data) {
		t.Error("fragment writer output does not match input")
	}
}

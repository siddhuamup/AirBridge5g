package privacy

import (
	"crypto/rand"
	"errors"
	"fmt"
	"io"
	"math/big"
	"sync/atomic"
)

// Fragmentation strategy constants.
const (
	DefaultFragmentSize    = 512   // Default max fragment size in bytes
	MinFragmentSize        = 64    // Minimum fragment size
	MaxFragmentSize        = 4096  // Maximum fragment size
	TLSRecordHeaderLen     = 5    // TLS record header: type(1) + version(2) + length(2)
	TLSContentTypeHandshake = 0x16
	TLSContentTypeAppData   = 0x17
)

// Fragment strategy types.
type FragmentStrategy int

const (
	// StrategyFixed uses a fixed fragment size.
	StrategyFixed FragmentStrategy = iota
	// StrategyRandom uses randomized fragment sizes within bounds.
	StrategyRandom
	// StrategyTLSSplit splits at TLS record boundaries.
	StrategyTLSSplit
)

// Errors returned by the fragmenter.
var (
	ErrFragmentTooSmall = errors.New("fragment size below minimum")
	ErrEmptyPayload     = errors.New("empty payload")
)

// FragmentStats tracks fragmentation statistics.
type FragmentStats struct {
	PacketsFragmented  atomic.Int64
	FragmentsCreated   atomic.Int64
	TLSRecordsSplit    atomic.Int64
	BytesProcessed     atomic.Int64
}

// FragmentStatsSnapshot is an immutable view of fragmentation stats.
type FragmentStatsSnapshot struct {
	PacketsFragmented int64
	FragmentsCreated  int64
	TLSRecordsSplit   int64
	BytesProcessed    int64
}

// Snapshot returns a point-in-time copy.
func (s *FragmentStats) Snapshot() FragmentStatsSnapshot {
	return FragmentStatsSnapshot{
		PacketsFragmented: s.PacketsFragmented.Load(),
		FragmentsCreated:  s.FragmentsCreated.Load(),
		TLSRecordsSplit:   s.TLSRecordsSplit.Load(),
		BytesProcessed:    s.BytesProcessed.Load(),
	}
}

// FragmenterConfig configures the packet fragmenter.
type FragmenterConfig struct {
	Strategy       FragmentStrategy
	MaxFragmentLen int  // Maximum bytes per fragment
	MinFragmentLen int  // Minimum bytes per fragment (for random strategy)
	Enabled        bool
}

// DefaultFragmenterConfig returns sensible defaults.
func DefaultFragmenterConfig() FragmenterConfig {
	return FragmenterConfig{
		Strategy:       StrategyRandom,
		MaxFragmentLen: DefaultFragmentSize,
		MinFragmentLen: MinFragmentSize,
		Enabled:        true,
	}
}

// Fragmenter splits data streams into smaller segments for DPI resilience.
type Fragmenter struct {
	cfg   FragmenterConfig
	stats FragmentStats
}

// NewFragmenter creates a new fragmenter with the given config.
func NewFragmenter(cfg FragmenterConfig) (*Fragmenter, error) {
	if cfg.MaxFragmentLen < MinFragmentSize {
		return nil, fmt.Errorf("%w: %d < %d", ErrFragmentTooSmall, cfg.MaxFragmentLen, MinFragmentSize)
	}
	if cfg.MinFragmentLen <= 0 {
		cfg.MinFragmentLen = MinFragmentSize
	}
	if cfg.MinFragmentLen > cfg.MaxFragmentLen {
		cfg.MinFragmentLen = cfg.MaxFragmentLen
	}
	return &Fragmenter{cfg: cfg}, nil
}

// GetStats returns current fragmentation statistics.
func (f *Fragmenter) GetStats() FragmentStatsSnapshot {
	return f.stats.Snapshot()
}

// Fragment splits a data payload into smaller segments.
// Returns a slice of fragments that, when concatenated, reproduce the original payload.
func (f *Fragmenter) Fragment(payload []byte) ([][]byte, error) {
	if !f.cfg.Enabled {
		return [][]byte{payload}, nil
	}
	if len(payload) == 0 {
		return nil, ErrEmptyPayload
	}

	f.stats.BytesProcessed.Add(int64(len(payload)))

	switch f.cfg.Strategy {
	case StrategyFixed:
		return f.fragmentFixed(payload)
	case StrategyRandom:
		return f.fragmentRandom(payload)
	case StrategyTLSSplit:
		return f.fragmentTLSRecord(payload)
	default:
		return f.fragmentFixed(payload)
	}
}

// fragmentFixed splits into equally-sized chunks.
func (f *Fragmenter) fragmentFixed(payload []byte) ([][]byte, error) {
	size := f.cfg.MaxFragmentLen
	fragments := make([][]byte, 0, (len(payload)/size)+1)

	for offset := 0; offset < len(payload); offset += size {
		end := offset + size
		if end > len(payload) {
			end = len(payload)
		}
		// Create a copy to avoid aliasing the original slice
		frag := make([]byte, end-offset)
		copy(frag, payload[offset:end])
		fragments = append(fragments, frag)
	}

	f.stats.PacketsFragmented.Add(1)
	f.stats.FragmentsCreated.Add(int64(len(fragments)))
	return fragments, nil
}

// fragmentRandom splits into randomly-sized chunks within configured bounds.
func (f *Fragmenter) fragmentRandom(payload []byte) ([][]byte, error) {
	fragments := make([][]byte, 0)
	offset := 0

	for offset < len(payload) {
		fragSize, err := randomIntRange(f.cfg.MinFragmentLen, f.cfg.MaxFragmentLen)
		if err != nil {
			// Fallback to fixed size on RNG failure
			fragSize = f.cfg.MaxFragmentLen
		}

		end := offset + fragSize
		if end > len(payload) {
			end = len(payload)
		}

		frag := make([]byte, end-offset)
		copy(frag, payload[offset:end])
		fragments = append(fragments, frag)
		offset = end
	}

	f.stats.PacketsFragmented.Add(1)
	f.stats.FragmentsCreated.Add(int64(len(fragments)))
	return fragments, nil
}

// fragmentTLSRecord splits TLS records into smaller TLS records.
// This is particularly effective against DPI because each resulting
// fragment is a valid TLS record.
func (f *Fragmenter) fragmentTLSRecord(payload []byte) ([][]byte, error) {
	if len(payload) < TLSRecordHeaderLen {
		// Not a TLS record; fall back to random fragmentation
		return f.fragmentRandom(payload)
	}

	contentType := payload[0]
	if contentType != TLSContentTypeHandshake && contentType != TLSContentTypeAppData {
		return f.fragmentRandom(payload)
	}

	// Parse TLS record header
	tlsVersion := payload[1:3]
	recordLen := int(payload[3])<<8 | int(payload[4])

	if len(payload) < TLSRecordHeaderLen+recordLen {
		return f.fragmentRandom(payload)
	}

	// Split the TLS record payload into smaller TLS records
	recordPayload := payload[TLSRecordHeaderLen : TLSRecordHeaderLen+recordLen]
	fragments := make([][]byte, 0)

	maxPayload := f.cfg.MaxFragmentLen - TLSRecordHeaderLen
	if maxPayload < 1 {
		maxPayload = 1
	}

	for offset := 0; offset < len(recordPayload); {
		chunkSize, err := randomIntRange(1, maxPayload)
		if err != nil {
			chunkSize = maxPayload
		}
		end := offset + chunkSize
		if end > len(recordPayload) {
			end = len(recordPayload)
		}

		chunk := recordPayload[offset:end]

		// Build a new TLS record with the same type and version
		record := make([]byte, TLSRecordHeaderLen+len(chunk))
		record[0] = contentType
		record[1] = tlsVersion[0]
		record[2] = tlsVersion[1]
		record[3] = byte(len(chunk) >> 8)
		record[4] = byte(len(chunk) & 0xFF)
		copy(record[TLSRecordHeaderLen:], chunk)

		fragments = append(fragments, record)
		offset = end
	}

	// Append any remaining data after the TLS record
	remaining := payload[TLSRecordHeaderLen+recordLen:]
	if len(remaining) > 0 {
		extraFrags, err := f.fragmentRandom(remaining)
		if err == nil {
			fragments = append(fragments, extraFrags...)
		}
	}

	f.stats.PacketsFragmented.Add(1)
	f.stats.FragmentsCreated.Add(int64(len(fragments)))
	f.stats.TLSRecordsSplit.Add(1)
	return fragments, nil
}

// FragmentWriter wraps an io.Writer and transparently fragments data before writing.
type FragmentWriter struct {
	writer     io.Writer
	fragmenter *Fragmenter
}

// NewFragmentWriter creates a writer that fragments data before forwarding.
func NewFragmentWriter(w io.Writer, f *Fragmenter) *FragmentWriter {
	return &FragmentWriter{writer: w, fragmenter: f}
}

// Write fragments the data and writes each fragment to the underlying writer.
func (fw *FragmentWriter) Write(p []byte) (int, error) {
	fragments, err := fw.fragmenter.Fragment(p)
	if err != nil {
		return 0, err
	}

	totalWritten := 0
	for _, frag := range fragments {
		n, err := fw.writer.Write(frag)
		totalWritten += n
		if err != nil {
			return totalWritten, err
		}
	}

	return len(p), nil
}

// randomIntRange returns a cryptographically random integer in [min, max].
func randomIntRange(min, max int) (int, error) {
	if min >= max {
		return min, nil
	}
	rangeSize := big.NewInt(int64(max - min + 1))
	n, err := rand.Int(rand.Reader, rangeSize)
	if err != nil {
		return min, err
	}
	return min + int(n.Int64()), nil
}

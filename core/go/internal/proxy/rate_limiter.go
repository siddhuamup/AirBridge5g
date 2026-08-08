package proxy

import (
	"io"
	"sync"
	"time"
)

// RateLimiter implements token bucket rate limiting for QoS bandwidth control.
type RateLimiter struct {
	bytesPerSec int64
	tokens      int64
	maxBurst    int64
	mu          sync.Mutex
	lastRefill  time.Time
	enabled     bool
}

// NewRateLimiter creates a rate limiter with the given bandwidth limit.
// Set bytesPerSec to 0 to disable rate limiting.
func NewRateLimiter(bytesPerSec int64) *RateLimiter {
	if bytesPerSec <= 0 {
		return &RateLimiter{enabled: false}
	}
	maxBurst := bytesPerSec // Allow 1 second of burst
	return &RateLimiter{
		bytesPerSec: bytesPerSec,
		tokens:      maxBurst,
		maxBurst:    maxBurst,
		lastRefill:  time.Now(),
		enabled:     true,
	}
}

// IsEnabled returns whether rate limiting is active.
func (rl *RateLimiter) IsEnabled() bool {
	return rl.enabled
}

// SetRate updates the bandwidth limit dynamically.
func (rl *RateLimiter) SetRate(bytesPerSec int64) {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	if bytesPerSec <= 0 {
		rl.enabled = false
		return
	}
	rl.bytesPerSec = bytesPerSec
	rl.maxBurst = bytesPerSec
	rl.enabled = true
}

// Wait blocks until enough tokens are available for n bytes.
func (rl *RateLimiter) Wait(n int) {
	if !rl.enabled || n <= 0 {
		return
	}

	for {
		rl.mu.Lock()
		rl.refill()
		if rl.tokens >= int64(n) {
			rl.tokens -= int64(n)
			rl.mu.Unlock()
			return
		}
		deficit := int64(n) - rl.tokens
		waitTime := time.Duration(float64(deficit) / float64(rl.bytesPerSec) * float64(time.Second))
		rl.mu.Unlock()

		if waitTime < time.Millisecond {
			waitTime = time.Millisecond
		}
		time.Sleep(waitTime)
	}
}

// refill adds tokens based on elapsed time (must be called under lock).
func (rl *RateLimiter) refill() {
	now := time.Now()
	elapsed := now.Sub(rl.lastRefill)
	newTokens := int64(elapsed.Seconds() * float64(rl.bytesPerSec))
	if newTokens > 0 {
		rl.tokens += newTokens
		if rl.tokens > rl.maxBurst {
			rl.tokens = rl.maxBurst
		}
		rl.lastRefill = now
	}
}

// RateLimitedWriter wraps an io.Writer with bandwidth limiting.
type RateLimitedWriter struct {
	w       io.Writer
	limiter *RateLimiter
}

// NewRateLimitedWriter creates a writer that enforces the given rate limit.
func NewRateLimitedWriter(w io.Writer, limiter *RateLimiter) *RateLimitedWriter {
	return &RateLimitedWriter{w: w, limiter: limiter}
}

func (rlw *RateLimitedWriter) Write(p []byte) (int, error) {
	if rlw.limiter != nil && rlw.limiter.IsEnabled() {
		rlw.limiter.Wait(len(p))
	}
	return rlw.w.Write(p)
}

// RateLimitedReader wraps an io.Reader with bandwidth limiting.
type RateLimitedReader struct {
	r       io.Reader
	limiter *RateLimiter
}

// NewRateLimitedReader creates a reader that enforces the given rate limit.
func NewRateLimitedReader(r io.Reader, limiter *RateLimiter) *RateLimitedReader {
	return &RateLimitedReader{r: r, limiter: limiter}
}

func (rlr *RateLimitedReader) Read(p []byte) (int, error) {
	n, err := rlr.r.Read(p)
	if n > 0 && rlr.limiter != nil && rlr.limiter.IsEnabled() {
		rlr.limiter.Wait(n)
	}
	return n, err
}

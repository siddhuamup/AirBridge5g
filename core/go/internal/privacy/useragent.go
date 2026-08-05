package privacy

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync/atomic"
)

// Default mobile User-Agent strings for harmonization.
const (
	UAChromeMobile = "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36"
	UASafariMobile = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
)

// Headers that can reveal desktop OS fingerprints.
var desktopRevealingHeaders = []string{
	"Sec-Ch-Ua-Platform",
	"Sec-Ch-Ua-Platform-Version",
	"Sec-Ch-Ua-Model",
	"Sec-Ch-Ua-Full-Version",
	"Sec-Ch-Ua-Full-Version-List",
	"Sec-Ch-Ua-Arch",
	"Sec-Ch-Ua-Bitness",
	"Sec-Ch-Ua-Wow64",
	"X-Requested-With",
}

// UAHarmonizeStats tracks User-Agent harmonization statistics.
type UAHarmonizeStats struct {
	RequestsProcessed atomic.Int64
	RequestsModified  atomic.Int64
	HeadersStripped   atomic.Int64
}

// UAHarmonizeStatsSnapshot is an immutable view.
type UAHarmonizeStatsSnapshot struct {
	RequestsProcessed int64
	RequestsModified  int64
	HeadersStripped   int64
}

// Snapshot returns a point-in-time copy.
func (s *UAHarmonizeStats) Snapshot() UAHarmonizeStatsSnapshot {
	return UAHarmonizeStatsSnapshot{
		RequestsProcessed: s.RequestsProcessed.Load(),
		RequestsModified:  s.RequestsModified.Load(),
		HeadersStripped:   s.HeadersStripped.Load(),
	}
}

// UAHarmonizerConfig configures User-Agent harmonization.
type UAHarmonizerConfig struct {
	TargetUA          string   // Mobile User-Agent to replace desktop UAs with
	StripHeaders      []string // Additional headers to strip
	StripClientHints  bool     // Strip Sec-CH-UA-* headers
	Enabled           bool
}

// DefaultUAHarmonizerConfig returns Android Chrome mobile config.
func DefaultUAHarmonizerConfig() UAHarmonizerConfig {
	return UAHarmonizerConfig{
		TargetUA:         UAChromeMobile,
		StripHeaders:     desktopRevealingHeaders,
		StripClientHints: true,
		Enabled:          true,
	}
}

// UAHarmonizer rewrites HTTP headers to mask desktop OS fingerprints.
type UAHarmonizer struct {
	cfg   UAHarmonizerConfig
	stats UAHarmonizeStats
}

// NewUAHarmonizer creates a new User-Agent harmonizer.
func NewUAHarmonizer(cfg UAHarmonizerConfig) *UAHarmonizer {
	if cfg.TargetUA == "" {
		cfg.TargetUA = UAChromeMobile
	}
	return &UAHarmonizer{cfg: cfg}
}

// GetStats returns current harmonization statistics.
func (h *UAHarmonizer) GetStats() UAHarmonizeStatsSnapshot {
	return h.stats.Snapshot()
}

// HarmonizeHTTPRequest modifies an HTTP request to appear mobile-originated.
// Returns a new request with harmonized headers (immutable pattern).
func (h *UAHarmonizer) HarmonizeHTTPRequest(req *http.Request) *http.Request {
	if !h.cfg.Enabled || req == nil {
		return req
	}

	h.stats.RequestsProcessed.Add(1)

	// Clone the request to preserve immutability
	newReq := req.Clone(req.Context())
	modified := false

	// Replace User-Agent if it looks like a desktop browser
	currentUA := newReq.Header.Get("User-Agent")
	if currentUA != "" && isDesktopUA(currentUA) {
		newReq.Header.Set("User-Agent", h.cfg.TargetUA)
		modified = true
	}

	// Strip desktop-revealing headers
	if h.cfg.StripClientHints {
		for _, header := range h.cfg.StripHeaders {
			if newReq.Header.Get(header) != "" {
				newReq.Header.Del(header)
				h.stats.HeadersStripped.Add(1)
				modified = true
			}
		}
	}

	// Set mobile-appropriate Sec-CH-UA if Client Hints were present
	if newReq.Header.Get("Sec-Ch-Ua") != "" {
		newReq.Header.Set("Sec-Ch-Ua", `"Chromium";v="125", "Google Chrome";v="125", "Not-A.Brand";v="99"`)
		newReq.Header.Set("Sec-Ch-Ua-Mobile", "?1")
		newReq.Header.Set("Sec-Ch-Ua-Platform", `"Android"`)
		modified = true
	}

	if modified {
		h.stats.RequestsModified.Add(1)
	}

	return newReq
}

// HarmonizeRawHTTP processes raw HTTP bytes and rewrites headers in-stream.
// This is used when the proxy operates at the TCP level without full HTTP parsing.
func (h *UAHarmonizer) HarmonizeRawHTTP(data []byte) ([]byte, error) {
	if !h.cfg.Enabled {
		return data, nil
	}

	// Quick check: does this look like an HTTP request?
	if !isHTTPRequest(data) {
		return data, nil
	}

	h.stats.RequestsProcessed.Add(1)

	reader := bufio.NewReader(bytes.NewReader(data))
	req, err := http.ReadRequest(reader)
	if err != nil {
		// Not a valid HTTP request, pass through unchanged
		return data, nil
	}
	defer req.Body.Close()

	harmonized := h.HarmonizeHTTPRequest(req)

	// Serialize back to bytes
	var buf bytes.Buffer
	if err := harmonized.Write(&buf); err != nil {
		return data, fmt.Errorf("serialize harmonized request: %w", err)
	}

	// Append any remaining body data that wasn't part of headers
	remaining, _ := io.ReadAll(reader)
	buf.Write(remaining)

	return buf.Bytes(), nil
}

// isDesktopUA checks if a User-Agent string appears to be from a desktop browser.
func isDesktopUA(ua string) bool {
	ua = strings.ToLower(ua)

	// Desktop-specific indicators
	desktopIndicators := []string{
		"windows nt",
		"macintosh",
		"mac os x",
		"x11; linux",
		"x11; ubuntu",
		"x11; fedora",
		"cros",
	}

	// Mobile indicators (if present, it's already mobile)
	mobileIndicators := []string{
		"mobile",
		"android",
		"iphone",
		"ipad",
		"ipod",
	}

	for _, indicator := range mobileIndicators {
		if strings.Contains(ua, indicator) {
			return false
		}
	}

	for _, indicator := range desktopIndicators {
		if strings.Contains(ua, indicator) {
			return true
		}
	}

	return false
}

// isHTTPRequest checks if a byte slice starts with an HTTP method.
func isHTTPRequest(data []byte) bool {
	if len(data) < 4 {
		return false
	}
	methods := []string{"GET ", "POST", "PUT ", "DELE", "HEAD", "OPTI", "PATC", "CONN"}
	prefix := string(data[:4])
	for _, m := range methods {
		if prefix == m {
			return true
		}
	}
	return false
}

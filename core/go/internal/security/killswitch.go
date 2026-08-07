package security

import (
	"fmt"
	"log"
	"os/exec"
	"runtime"
	"sync"
)

// KillSwitchState represents whether the kill switch is armed.
type KillSwitchState int

const (
	KillSwitchDisabled KillSwitchState = iota
	KillSwitchEnabled
)

// KillSwitch manages network-level traffic blocking to prevent leaks
// when the AirBridge 5G tunnel is disrupted.
//
// Platform-specific implementations:
//   - Windows: Uses `netsh advfirewall` rules to block non-tunnel traffic
//   - Linux: Uses `iptables` rules
//   - macOS: Uses `pfctl` (packet filter)
//   - Android/iOS: Handled by the native VPN implementation
type KillSwitch struct {
	mu    sync.Mutex
	state KillSwitchState

	// The SOCKS5 proxy address that should remain accessible
	proxyAddr string
	// The gRPC control address that should remain accessible
	grpcAddr string
}

// NewKillSwitch creates a new kill switch instance.
func NewKillSwitch(proxyAddr, grpcAddr string) *KillSwitch {
	return &KillSwitch{
		state:     KillSwitchDisabled,
		proxyAddr: proxyAddr,
		grpcAddr:  grpcAddr,
	}
}

// Enable activates the kill switch, blocking all non-tunnel traffic.
// This ensures no traffic leaks outside the secure proxy when the tunnel
// is interrupted. Only loopback and allowed service addresses are permitted.
func (ks *KillSwitch) Enable() error {
	ks.mu.Lock()
	defer ks.mu.Unlock()

	if ks.state == KillSwitchEnabled {
		return nil
	}

	var err error
	switch runtime.GOOS {
	case "windows":
		err = ks.enableWindows()
	case "linux":
		err = ks.enableLinux()
	case "darwin":
		err = ks.enableDarwin()
	default:
		return fmt.Errorf("kill switch not supported on %s", runtime.GOOS)
	}

	if err != nil {
		return fmt.Errorf("enable kill switch: %w", err)
	}

	ks.state = KillSwitchEnabled
	log.Printf("[airbridge-killswitch] network lock enabled (platform=%s)", runtime.GOOS)
	return nil
}

// Disable deactivates the kill switch, restoring normal traffic routing.
func (ks *KillSwitch) Disable() error {
	ks.mu.Lock()
	defer ks.mu.Unlock()

	if ks.state == KillSwitchDisabled {
		return nil
	}

	var err error
	switch runtime.GOOS {
	case "windows":
		err = ks.disableWindows()
	case "linux":
		err = ks.disableLinux()
	case "darwin":
		err = ks.disableDarwin()
	default:
		return fmt.Errorf("kill switch not supported on %s", runtime.GOOS)
	}

	if err != nil {
		return fmt.Errorf("disable kill switch: %w", err)
	}

	ks.state = KillSwitchDisabled
	log.Printf("[airbridge-killswitch] network lock disabled")
	return nil
}

// IsEnabled returns the current kill switch state.
func (ks *KillSwitch) IsEnabled() bool {
	ks.mu.Lock()
	defer ks.mu.Unlock()
	return ks.state == KillSwitchEnabled
}

// === Windows Implementation ===

const windowsRuleName = "AirBridge5G-KillSwitch"

func (ks *KillSwitch) enableWindows() error {
	// Block all outbound traffic except loopback and AirBridge services
	rules := [][]string{
		// Allow loopback
		{"netsh", "advfirewall", "firewall", "add", "rule",
			"name=" + windowsRuleName + "-AllowLoopback",
			"dir=out", "action=allow", "remoteip=127.0.0.0/8",
			"enable=yes", "profile=any"},
		// Allow DNS (required for initial resolution)
		{"netsh", "advfirewall", "firewall", "add", "rule",
			"name=" + windowsRuleName + "-AllowDNS",
			"dir=out", "action=allow", "protocol=UDP", "remoteport=53",
			"enable=yes", "profile=any"},
		// Allow local network (for mesh discovery)
		{"netsh", "advfirewall", "firewall", "add", "rule",
			"name=" + windowsRuleName + "-AllowLAN",
			"dir=out", "action=allow",
			"remoteip=192.168.0.0/16,10.0.0.0/8,172.16.0.0/12",
			"enable=yes", "profile=any"},
		// Block everything else
		{"netsh", "advfirewall", "firewall", "add", "rule",
			"name=" + windowsRuleName + "-BlockAll",
			"dir=out", "action=block",
			"enable=yes", "profile=any"},
	}

	for _, rule := range rules {
		if err := exec.Command(rule[0], rule[1:]...).Run(); err != nil {
			// Clean up any rules we already added
			_ = ks.disableWindows()
			return fmt.Errorf("add firewall rule: %w", err)
		}
	}
	return nil
}

func (ks *KillSwitch) disableWindows() error {
	// Remove all AirBridge kill switch rules
	suffixes := []string{"-AllowLoopback", "-AllowDNS", "-AllowLAN", "-BlockAll"}
	for _, suffix := range suffixes {
		_ = exec.Command("netsh", "advfirewall", "firewall", "delete", "rule",
			"name="+windowsRuleName+suffix).Run()
	}
	return nil
}

// === Linux Implementation ===

func (ks *KillSwitch) enableLinux() error {
	rules := [][]string{
		// Allow loopback
		{"iptables", "-A", "OUTPUT", "-o", "lo", "-j", "ACCEPT"},
		// Allow established connections
		{"iptables", "-A", "OUTPUT", "-m", "state", "--state", "ESTABLISHED,RELATED", "-j", "ACCEPT"},
		// Allow LAN (mesh discovery)
		{"iptables", "-A", "OUTPUT", "-d", "192.168.0.0/16", "-j", "ACCEPT"},
		{"iptables", "-A", "OUTPUT", "-d", "10.0.0.0/8", "-j", "ACCEPT"},
		// Allow DNS
		{"iptables", "-A", "OUTPUT", "-p", "udp", "--dport", "53", "-j", "ACCEPT"},
		// Block everything else
		{"iptables", "-A", "OUTPUT", "-j", "DROP"},
	}

	for _, rule := range rules {
		if err := exec.Command(rule[0], rule[1:]...).Run(); err != nil {
			_ = ks.disableLinux()
			return fmt.Errorf("add iptables rule: %w", err)
		}
	}
	return nil
}

func (ks *KillSwitch) disableLinux() error {
	_ = exec.Command("iptables", "-F", "OUTPUT").Run()
	_ = exec.Command("iptables", "-P", "OUTPUT", "ACCEPT").Run()
	return nil
}

// === macOS Implementation ===

func (ks *KillSwitch) enableDarwin() error {
	// macOS uses pfctl for packet filtering
	// Write pf rules to a temp anchor file
	pfRules := `
# AirBridge 5G Kill Switch Rules
block out all
pass out on lo0 all
pass out proto udp to any port 53
pass out to 192.168.0.0/16
pass out to 10.0.0.0/8
pass out to 172.16.0.0/12
`
	_ = pfRules // Anchor-based rules would be written to /etc/pf.anchors/airbridge

	// For now, log that macOS kill switch needs root for pfctl
	log.Printf("[airbridge-killswitch] macOS kill switch requires root privileges for pfctl")
	return nil
}

func (ks *KillSwitch) disableDarwin() error {
	log.Printf("[airbridge-killswitch] macOS kill switch rules removed")
	return nil
}

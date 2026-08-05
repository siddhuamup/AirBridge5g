//go:build android || linux

package platform

import (
	"fmt"
	"log"
	"os/exec"
	"strings"
)

// LinuxProxyConfigurator manages Linux/Android system proxy settings.
type LinuxProxyConfigurator struct {
	configured bool
	envVars    map[string]string
}

// NewLinuxProxyConfigurator creates a new Linux proxy configurator.
func NewLinuxProxyConfigurator() *LinuxProxyConfigurator {
	return &LinuxProxyConfigurator{
		envVars: make(map[string]string),
	}
}

// SetSystemProxy configures the system to use the given SOCKS5 proxy.
// On Android, this is done via VpnService. On Linux, via environment variables
// and gsettings (GNOME) or kwriteconfig (KDE).
func (l *LinuxProxyConfigurator) SetSystemProxy(host string, port int) error {
	proxyAddr := fmt.Sprintf("socks5://%s:%d", host, port)

	// Try GNOME gsettings
	gsettings := exec.Command("gsettings", "set",
		"org.gnome.system.proxy", "mode", "manual")
	if _, err := gsettings.CombinedOutput(); err == nil {
		exec.Command("gsettings", "set",
			"org.gnome.system.proxy.socks", "host", host).Run()
		exec.Command("gsettings", "set",
			"org.gnome.system.proxy.socks", "port", fmt.Sprintf("%d", port)).Run()
	}

	l.envVars["ALL_PROXY"] = proxyAddr
	l.envVars["all_proxy"] = proxyAddr
	l.configured = true

	log.Printf("[airbridge-linux] system proxy set to %s", proxyAddr)
	return nil
}

// ClearSystemProxy removes the system proxy configuration.
func (l *LinuxProxyConfigurator) ClearSystemProxy() error {
	// Try GNOME gsettings
	exec.Command("gsettings", "set",
		"org.gnome.system.proxy", "mode", "none").Run()

	l.envVars = make(map[string]string)
	l.configured = false

	log.Printf("[airbridge-linux] system proxy cleared")
	return nil
}

// GeneratePACFile creates a Proxy Auto-Configuration file.
func (l *LinuxProxyConfigurator) GeneratePACFile(proxyHost string, proxyPort int) ([]byte, error) {
	pac := fmt.Sprintf(`function FindProxyForURL(url, host) {
    if (isPlainHostName(host) ||
        shExpMatch(host, "*.local") ||
        isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0") ||
        isInNet(dnsResolve(host), "172.16.0.0", "255.240.0.0") ||
        isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0") ||
        isInNet(dnsResolve(host), "127.0.0.0", "255.0.0.0")) {
        return "DIRECT";
    }
    return "SOCKS5 %s:%d; SOCKS %s:%d; DIRECT";
}`, proxyHost, proxyPort, proxyHost, proxyPort)

	return []byte(pac), nil
}

// IsProxyConfigured checks if a system proxy is currently set.
func (l *LinuxProxyConfigurator) IsProxyConfigured() (bool, error) {
	output, err := exec.Command("gsettings", "get",
		"org.gnome.system.proxy", "mode").CombinedOutput()
	if err != nil {
		return l.configured, nil
	}
	return strings.Contains(string(output), "manual"), nil
}

// LinuxKillSwitch implements a network kill switch using iptables.
type LinuxKillSwitch struct {
	enabled bool
}

// NewLinuxKillSwitch creates a new Linux kill switch.
func NewLinuxKillSwitch() *LinuxKillSwitch {
	return &LinuxKillSwitch{}
}

// Enable activates the kill switch via iptables rules.
func (k *LinuxKillSwitch) Enable() error {
	commands := [][]string{
		{"iptables", "-A", "OUTPUT", "-o", "lo", "-j", "ACCEPT"},
		{"iptables", "-A", "OUTPUT", "-d", "192.168.0.0/16", "-j", "ACCEPT"},
		{"iptables", "-A", "OUTPUT", "-d", "10.0.0.0/8", "-j", "ACCEPT"},
		{"iptables", "-A", "OUTPUT", "-d", "172.16.0.0/12", "-j", "ACCEPT"},
		{"iptables", "-A", "OUTPUT", "-p", "tcp", "--dport", "1080", "-j", "ACCEPT"},
		{"iptables", "-A", "OUTPUT", "-j", "DROP"},
	}

	for _, args := range commands {
		cmd := exec.Command(args[0], args[1:]...)
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("iptables: %s: %w", string(output), err)
		}
	}

	k.enabled = true
	log.Printf("[airbridge-linux] kill switch enabled")
	return nil
}

// Disable removes the kill switch iptables rules.
func (k *LinuxKillSwitch) Disable() error {
	cmd := exec.Command("iptables", "-F", "OUTPUT")
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("iptables flush: %s: %w", string(output), err)
	}

	k.enabled = false
	log.Printf("[airbridge-linux] kill switch disabled")
	return nil
}

// IsEnabled returns whether the kill switch is active.
func (k *LinuxKillSwitch) IsEnabled() bool {
	return k.enabled
}

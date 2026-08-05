//go:build darwin

package platform

import (
	"fmt"
	"log"
	"os/exec"
	"strings"
)

// DarwinProxyConfigurator manages macOS/iOS system proxy settings.
type DarwinProxyConfigurator struct {
	configured     bool
	networkService string
}

// NewDarwinProxyConfigurator creates a new macOS proxy configurator.
func NewDarwinProxyConfigurator() *DarwinProxyConfigurator {
	return &DarwinProxyConfigurator{
		networkService: detectActiveNetworkService(),
	}
}

// SetSystemProxy configures macOS to use the given SOCKS5 proxy
// via networksetup command.
func (d *DarwinProxyConfigurator) SetSystemProxy(host string, port int) error {
	svc := d.networkService

	cmd := exec.Command("networksetup", "-setsocksfirewallproxy",
		svc, host, fmt.Sprintf("%d", port))
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("networksetup set socks: %s: %w", string(output), err)
	}

	cmd2 := exec.Command("networksetup", "-setsocksfirewallproxystate", svc, "on")
	if output, err := cmd2.CombinedOutput(); err != nil {
		return fmt.Errorf("networksetup enable socks: %s: %w", string(output), err)
	}

	d.configured = true
	log.Printf("[airbridge-darwin] system SOCKS proxy set to %s:%d on %s", host, port, svc)
	return nil
}

// ClearSystemProxy removes the macOS system proxy configuration.
func (d *DarwinProxyConfigurator) ClearSystemProxy() error {
	cmd := exec.Command("networksetup", "-setsocksfirewallproxystate",
		d.networkService, "off")
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("networksetup disable socks: %s: %w", string(output), err)
	}

	d.configured = false
	log.Printf("[airbridge-darwin] system proxy cleared")
	return nil
}

// GeneratePACFile creates a Proxy Auto-Configuration file for iOS/macOS.
func (d *DarwinProxyConfigurator) GeneratePACFile(proxyHost string, proxyPort int) ([]byte, error) {
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
func (d *DarwinProxyConfigurator) IsProxyConfigured() (bool, error) {
	cmd := exec.Command("networksetup", "-getsocksfirewallproxy", d.networkService)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return d.configured, nil
	}
	return strings.Contains(string(output), "Enabled: Yes"), nil
}

// DarwinKillSwitch implements a network kill switch using pf (packet filter).
type DarwinKillSwitch struct {
	enabled bool
}

// NewDarwinKillSwitch creates a new macOS kill switch.
func NewDarwinKillSwitch() *DarwinKillSwitch {
	return &DarwinKillSwitch{}
}

// Enable activates the kill switch via pf rules.
func (k *DarwinKillSwitch) Enable() error {
	// Write pf rules to temp file
	rules := `
# AirBridge Kill Switch
block out all
pass out on lo0
pass out to 192.168.0.0/16
pass out to 10.0.0.0/8
pass out to 172.16.0.0/12
pass out proto tcp to any port 1080
`
	cmd := exec.Command("bash", "-c",
		fmt.Sprintf("echo '%s' | sudo pfctl -ef -", rules))
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("pfctl enable: %s: %w", string(output), err)
	}

	k.enabled = true
	log.Printf("[airbridge-darwin] kill switch enabled")
	return nil
}

// Disable removes the kill switch pf rules.
func (k *DarwinKillSwitch) Disable() error {
	cmd := exec.Command("sudo", "pfctl", "-d")
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("pfctl disable: %s: %w", string(output), err)
	}

	k.enabled = false
	log.Printf("[airbridge-darwin] kill switch disabled")
	return nil
}

// IsEnabled returns whether the kill switch is active.
func (k *DarwinKillSwitch) IsEnabled() bool {
	return k.enabled
}

// detectActiveNetworkService finds the primary active network service.
func detectActiveNetworkService() string {
	cmd := exec.Command("networksetup", "-listallnetworkservices")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "Wi-Fi"
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "*") || strings.HasPrefix(line, "An asterisk") {
			continue
		}
		// Prefer Wi-Fi
		if strings.EqualFold(line, "Wi-Fi") || strings.EqualFold(line, "WiFi") {
			return line
		}
	}

	// Fallback to first non-header line
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" && !strings.HasPrefix(line, "An asterisk") {
			return line
		}
	}

	return "Wi-Fi"
}

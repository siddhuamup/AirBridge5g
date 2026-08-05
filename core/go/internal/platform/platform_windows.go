//go:build windows

package platform

import (
	"fmt"
	"log"
	"os/exec"
	"strings"
)

// WindowsProxyConfigurator manages Windows system proxy settings.
type WindowsProxyConfigurator struct {
	previousProxy string
	configured    bool
}

// NewWindowsProxyConfigurator creates a new Windows proxy configurator.
func NewWindowsProxyConfigurator() *WindowsProxyConfigurator {
	return &WindowsProxyConfigurator{}
}

// SetSystemProxy configures Windows to use the given SOCKS5 proxy
// via netsh and registry settings.
func (w *WindowsProxyConfigurator) SetSystemProxy(host string, port int) error {
	proxyAddr := fmt.Sprintf("socks=%s:%d", host, port)

	// Set proxy via netsh
	cmd := exec.Command("netsh", "winhttp", "set", "proxy",
		fmt.Sprintf("proxy-server=%s", proxyAddr))
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("netsh set proxy: %s: %w", string(output), err)
	}

	// Also set via registry for applications that use WinINet
	regCmd := exec.Command("reg", "add",
		`HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`,
		"/v", "ProxyEnable", "/t", "REG_DWORD", "/d", "1", "/f")
	if output, err := regCmd.CombinedOutput(); err != nil {
		log.Printf("[airbridge-win] registry ProxyEnable: %s: %v", string(output), err)
	}

	regCmd2 := exec.Command("reg", "add",
		`HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`,
		"/v", "ProxyServer", "/t", "REG_SZ", "/d", proxyAddr, "/f")
	if output, err := regCmd2.CombinedOutput(); err != nil {
		log.Printf("[airbridge-win] registry ProxyServer: %s: %v", string(output), err)
	}

	w.configured = true
	log.Printf("[airbridge-win] system proxy set to %s", proxyAddr)
	return nil
}

// ClearSystemProxy removes the Windows system proxy configuration.
func (w *WindowsProxyConfigurator) ClearSystemProxy() error {
	// Reset via netsh
	cmd := exec.Command("netsh", "winhttp", "reset", "proxy")
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("netsh reset proxy: %s: %w", string(output), err)
	}

	// Disable via registry
	regCmd := exec.Command("reg", "add",
		`HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`,
		"/v", "ProxyEnable", "/t", "REG_DWORD", "/d", "0", "/f")
	if output, err := regCmd.CombinedOutput(); err != nil {
		log.Printf("[airbridge-win] registry clear: %s: %v", string(output), err)
	}

	w.configured = false
	log.Printf("[airbridge-win] system proxy cleared")
	return nil
}

// GeneratePACFile creates a Proxy Auto-Configuration file for Windows.
func (w *WindowsProxyConfigurator) GeneratePACFile(proxyHost string, proxyPort int) ([]byte, error) {
	pac := fmt.Sprintf(`function FindProxyForURL(url, host) {
    // Direct connections for local/private addresses
    if (isPlainHostName(host) ||
        shExpMatch(host, "*.local") ||
        isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0") ||
        isInNet(dnsResolve(host), "172.16.0.0", "255.240.0.0") ||
        isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0") ||
        isInNet(dnsResolve(host), "127.0.0.0", "255.0.0.0")) {
        return "DIRECT";
    }
    // Route all other traffic through AirBridge SOCKS5 proxy
    return "SOCKS5 %s:%d; SOCKS %s:%d; DIRECT";
}`, proxyHost, proxyPort, proxyHost, proxyPort)

	return []byte(pac), nil
}

// IsProxyConfigured checks if a system proxy is currently set.
func (w *WindowsProxyConfigurator) IsProxyConfigured() (bool, error) {
	cmd := exec.Command("reg", "query",
		`HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`,
		"/v", "ProxyEnable")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return false, err
	}
	return strings.Contains(string(output), "0x1"), nil
}

// WindowsKillSwitch implements a network kill switch using Windows Firewall.
type WindowsKillSwitch struct {
	enabled bool
	rules   []string
}

// NewWindowsKillSwitch creates a new Windows kill switch.
func NewWindowsKillSwitch() *WindowsKillSwitch {
	return &WindowsKillSwitch{
		rules: []string{
			"AirBridge-KillSwitch-BlockOutbound",
			"AirBridge-KillSwitch-AllowTunnel",
			"AirBridge-KillSwitch-AllowLocal",
		},
	}
}

// Enable activates the kill switch by adding Windows Firewall rules.
func (k *WindowsKillSwitch) Enable() error {
	// Block all outbound traffic
	cmd := exec.Command("netsh", "advfirewall", "firewall", "add", "rule",
		"name=AirBridge-KillSwitch-BlockOutbound",
		"dir=out", "action=block", "enable=yes")
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("add block rule: %s: %w", string(output), err)
	}

	// Allow tunnel traffic (localhost proxy)
	cmd2 := exec.Command("netsh", "advfirewall", "firewall", "add", "rule",
		"name=AirBridge-KillSwitch-AllowTunnel",
		"dir=out", "action=allow",
		"remoteip=127.0.0.1", "enable=yes")
	if output, err := cmd2.CombinedOutput(); err != nil {
		return fmt.Errorf("add allow tunnel: %s: %w", string(output), err)
	}

	// Allow local network
	cmd3 := exec.Command("netsh", "advfirewall", "firewall", "add", "rule",
		"name=AirBridge-KillSwitch-AllowLocal",
		"dir=out", "action=allow",
		"remoteip=192.168.0.0/16,10.0.0.0/8,172.16.0.0/12", "enable=yes")
	if output, err := cmd3.CombinedOutput(); err != nil {
		return fmt.Errorf("add allow local: %s: %w", string(output), err)
	}

	k.enabled = true
	log.Printf("[airbridge-win] kill switch enabled")
	return nil
}

// Disable removes the kill switch firewall rules.
func (k *WindowsKillSwitch) Disable() error {
	for _, rule := range k.rules {
		cmd := exec.Command("netsh", "advfirewall", "firewall", "delete", "rule",
			fmt.Sprintf("name=%s", rule))
		if output, err := cmd.CombinedOutput(); err != nil {
			log.Printf("[airbridge-win] delete rule %s: %s: %v", rule, string(output), err)
		}
	}

	k.enabled = false
	log.Printf("[airbridge-win] kill switch disabled")
	return nil
}

// IsEnabled returns whether the kill switch is active.
func (k *WindowsKillSwitch) IsEnabled() bool {
	return k.enabled
}

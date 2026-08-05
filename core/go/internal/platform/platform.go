// Package platform provides OS-specific network configuration utilities
// for the AirBridge 5G daemon.
package platform

import "runtime"

// Platform identifies the current OS platform.
type Platform string

const (
	PlatformAndroid Platform = "android"
	PlatformIOS     Platform = "ios"
	PlatformWindows Platform = "windows"
	PlatformMacOS   Platform = "macos"
	PlatformLinux   Platform = "linux"
	PlatformUnknown Platform = "unknown"
)

// Detect returns the current platform.
func Detect() Platform {
	switch runtime.GOOS {
	case "android":
		return PlatformAndroid
	case "ios":
		return PlatformIOS
	case "windows":
		return PlatformWindows
	case "darwin":
		return PlatformMacOS
	case "linux":
		// Check if running on Android (Linux kernel)
		if isAndroidEnv() {
			return PlatformAndroid
		}
		return PlatformLinux
	default:
		return PlatformUnknown
	}
}

// String returns the platform name.
func (p Platform) String() string {
	return string(p)
}

// IsMobile returns true for mobile platforms.
func (p Platform) IsMobile() bool {
	return p == PlatformAndroid || p == PlatformIOS
}

// IsDesktop returns true for desktop platforms.
func (p Platform) IsDesktop() bool {
	return p == PlatformWindows || p == PlatformMacOS || p == PlatformLinux
}

// ProxyConfigurator configures system-level proxy settings.
type ProxyConfigurator interface {
	// SetSystemProxy configures the OS to use the given SOCKS5 proxy.
	SetSystemProxy(host string, port int) error

	// ClearSystemProxy removes the system proxy configuration.
	ClearSystemProxy() error

	// GeneratePACFile creates a Proxy Auto-Configuration file.
	GeneratePACFile(proxyHost string, proxyPort int) ([]byte, error)

	// IsProxyConfigured returns whether a system proxy is currently set.
	IsProxyConfigured() (bool, error)
}

// KillSwitch blocks all non-tunneled traffic to prevent data leakage.
type KillSwitch interface {
	// Enable activates the kill switch, blocking non-tunnel traffic.
	Enable() error

	// Disable deactivates the kill switch, restoring normal routing.
	Disable() error

	// IsEnabled returns whether the kill switch is active.
	IsEnabled() bool
}

// VPNAdapter provides OS-specific VPN tunnel management.
type VPNAdapter interface {
	// Start creates and activates the VPN tunnel.
	Start(config VPNConfig) error

	// Stop tears down the VPN tunnel.
	Stop() error

	// IsRunning returns whether the VPN tunnel is active.
	IsRunning() bool

	// GetTunnelFD returns the tunnel file descriptor (for Android VpnService).
	GetTunnelFD() (int, error)
}

// VPNConfig configures the VPN tunnel.
type VPNConfig struct {
	TunnelAddress string   // Local tunnel IP (e.g., "10.0.0.2/24")
	DNSServers    []string // DNS servers to use within the tunnel
	Routes        []string // Routes to redirect through the tunnel
	MTU           int      // Maximum Transmission Unit
	ProxyHost     string   // SOCKS5 proxy host
	ProxyPort     int      // SOCKS5 proxy port
}

// DefaultVPNConfig returns sensible defaults.
func DefaultVPNConfig() VPNConfig {
	return VPNConfig{
		TunnelAddress: "10.0.0.2/24",
		DNSServers:    []string{"1.1.1.1", "8.8.8.8"},
		Routes:        []string{"0.0.0.0/0"},
		MTU:           1500,
		ProxyHost:     "127.0.0.1",
		ProxyPort:     1080,
	}
}

// isAndroidEnv checks if the process is running on Android.
func isAndroidEnv() bool {
	// Android runs on Linux kernel but has specific env markers
	// In production, check for /system/build.prop or ANDROID_ROOT env var
	return false
}

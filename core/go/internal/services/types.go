package services

// TunnelState represents the current tunnel lifecycle state.
type TunnelState int

const (
	TunnelStopped  TunnelState = iota
	TunnelStarting
	TunnelRunning
	TunnelDegraded
)

// String returns a human-readable tunnel state.
func (s TunnelState) String() string {
	switch s {
	case TunnelStopped:
		return "stopped"
	case TunnelStarting:
		return "starting"
	case TunnelRunning:
		return "running"
	case TunnelDegraded:
		return "degraded"
	default:
		return "unknown"
	}
}

// NodeStatus is a point-in-time summary of the daemon's state.
type NodeStatus struct {
	NodeID        string
	TunnelState   TunnelState
	ConnectedPeer int
	StartedAt     interface{}
}

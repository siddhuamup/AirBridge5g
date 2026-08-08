package services

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"
	"net"
	"runtime"
	"time"

	controlv1 "github.com/example/securemesh/core/proto/control/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// GRPCServer implements the ControlPlane gRPC service interface.
type GRPCServer struct {
	controlv1.UnimplementedControlPlaneServer
	daemon   *Daemon
	server   *grpc.Server
	listener net.Listener
	addr     string
}

// NewGRPCServer creates a new gRPC server wrapper for the daemon.
func NewGRPCServer(daemon *Daemon, addr string) *GRPCServer {
	if addr == "" {
		addr = "127.0.0.1:50051"
	}
	return &GRPCServer{
		daemon: daemon,
		addr:   addr,
	}
}

// Start begins serving the gRPC control plane service.
func (s *GRPCServer) Start(ctx context.Context) error {
	var err error
	s.listener, err = net.Listen("tcp", s.addr)
	if err != nil {
		return fmt.Errorf("listen gRPC tcp on %s: %w", s.addr, err)
	}

	s.server = grpc.NewServer()
	controlv1.RegisterControlPlaneServer(s.server, s)

	log.Printf("[airbridge-grpc] gRPC server listening on %s", s.addr)

	go func() {
		if err := s.server.Serve(s.listener); err != nil && err != grpc.ErrServerStopped {
			log.Printf("[airbridge-grpc] serve error: %v", err)
		}
	}()

	go func() {
		<-ctx.Done()
		s.Stop()
	}()

	return nil
}

// Stop gracefully stops the gRPC server.
func (s *GRPCServer) Stop() {
	if s.server != nil {
		s.server.GracefulStop()
		log.Printf("[airbridge-grpc] gRPC server stopped")
	}
}

// GetStatus returns the daemon lifecycle and platform status.
func (s *GRPCServer) GetStatus(ctx context.Context, req *controlv1.GetStatusRequest) (*controlv1.GetStatusResponse, error) {
	nodeStatus, err := s.daemon.Status(ctx)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "get status: %v", err)
	}

	startedAt := s.daemon.StartedAt()
	uptime := int64(time.Since(startedAt).Seconds())

	return &controlv1.GetStatusResponse{
		NodeId:          nodeStatus.NodeID,
		TunnelState:     mapTunnelState(nodeStatus.TunnelState),
		Role:            mapNodeRole(s.daemon.GetRole()),
		ConnectedPeers:  uint32(nodeStatus.ConnectedPeer),
		StartedAtUnixMs: startedAt.UnixMilli(),
		UptimeSeconds:   uptime,
		Version:         s.daemon.cfg.Version,
		Platform:        runtime.GOOS,
	}, nil
}

// StartTunnel activates proxy and transport tunnels.
func (s *GRPCServer) StartTunnel(ctx context.Context, req *controlv1.StartTunnelRequest) (*controlv1.StartTunnelResponse, error) {
	role := mapProtoRole(req.Role)
	if err := s.daemon.SetRole(ctx, role); err != nil {
		return nil, status.Errorf(codes.Internal, "set role: %v", err)
	}

	if err := s.daemon.StartTunnel(ctx); err != nil {
		return nil, status.Errorf(codes.Internal, "start tunnel: %v", err)
	}

	return &controlv1.StartTunnelResponse{
		State:        mapTunnelState(s.daemon.TunnelState()),
		ProxyAddress: s.daemon.cfg.ProxyAddress,
		QuicPort:     uint32(s.daemon.cfg.QUICPort),
	}, nil
}

// StopTunnel deactivates proxy and transport tunnels.
func (s *GRPCServer) StopTunnel(ctx context.Context, req *controlv1.StopTunnelRequest) (*controlv1.StopTunnelResponse, error) {
	if err := s.daemon.StopTunnel(ctx); err != nil {
		return nil, status.Errorf(codes.Internal, "stop tunnel: %v", err)
	}

	return &controlv1.StopTunnelResponse{
		State: mapTunnelState(s.daemon.tunnelState),
	}, nil
}

// SetRole updates the node's operational role.
func (s *GRPCServer) SetRole(ctx context.Context, req *controlv1.SetRoleRequest) (*controlv1.SetRoleResponse, error) {
	role := mapProtoRole(req.Role)
	if err := s.daemon.SetRole(ctx, role); err != nil {
		return nil, status.Errorf(codes.Internal, "set role: %v", err)
	}

	return &controlv1.SetRoleResponse{
		Role:        req.Role,
		TunnelState: mapTunnelState(s.daemon.tunnelState),
	}, nil
}

// GetRole returns the node's current operational role.
func (s *GRPCServer) GetRole(ctx context.Context, req *controlv1.GetRoleRequest) (*controlv1.GetRoleResponse, error) {
	return &controlv1.GetRoleResponse{
		Role: mapNodeRole(s.daemon.GetRole()),
	}, nil
}

// GenerateQRCredentials returns a QR credential payload for client pairing.
func (s *GRPCServer) GenerateQRCredentials(ctx context.Context, req *controlv1.GenerateQRRequest) (*controlv1.GenerateQRResponse, error) {
	creds, err := s.daemon.GenerateQRCredentials()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "generate credentials: %v", err)
	}

	payload, err := EncodeQRPayload(creds)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "encode payload: %v", err)
	}

	keyBytes, _ := base64.StdEncoding.DecodeString(creds.EncryptionKey)

	return &controlv1.GenerateQRResponse{
		QrPayload:       payload,
		ProxyHost:       creds.ProxyHost,
		ProxyPort:       uint32(creds.ProxyPort),
		QuicPort:        uint32(creds.QUICPort),
		EncryptionKey:   keyBytes,
		ExpiresAtUnixMs: creds.ExpiresAt,
	}, nil
}

// ImportQRCredentials imports and validates a client QR code payload.
func (s *GRPCServer) ImportQRCredentials(ctx context.Context, req *controlv1.ImportQRRequest) (*controlv1.ImportQRResponse, error) {
	err := s.daemon.ImportQRCredentials(req.QrPayload)
	if err != nil {
		return &controlv1.ImportQRResponse{
			Success:      false,
			ErrorMessage: err.Error(),
		}, nil
	}

	creds, _ := DecodeQRPayload(req.QrPayload)

	return &controlv1.ImportQRResponse{
		Success:      true,
		PeerId:       creds.NodeID,
		ProxyAddress: fmt.Sprintf("%s:%d", creds.ProxyHost, creds.ProxyPort),
	}, nil
}

// GetTrafficStats returns the current traffic metrics snapshot.
func (s *GRPCServer) GetTrafficStats(ctx context.Context, req *controlv1.GetTrafficStatsRequest) (*controlv1.GetTrafficStatsResponse, error) {
	current, history := s.daemon.GetTrafficStats()

	historyProto := make([]*controlv1.TrafficSnapshot, len(history))
	for i, h := range history {
		historyProto[i] = &controlv1.TrafficSnapshot{
			BytesIn:           h.BytesIn,
			BytesOut:          h.BytesOut,
			ThroughputInBps:   h.ThroughputInBPS,
			ThroughputOutBps:  h.ThroughputOutBPS,
			ActiveConnections: h.ActiveConnections,
			TotalConnections:  h.TotalConnections,
			PacketsProcessed:  h.PacketsProcessed,
		}
	}

	return &controlv1.GetTrafficStatsResponse{
		Current: &controlv1.TrafficSnapshot{
			BytesIn:           current.BytesIn,
			BytesOut:          current.BytesOut,
			ThroughputInBps:   current.ThroughputInBPS,
			ThroughputOutBps:  current.ThroughputOutBPS,
			ActiveConnections: current.ActiveConnections,
			TotalConnections:  current.TotalConnections,
			PacketsProcessed:  current.PacketsProcessed,
		},
		History: historyProto,
	}, nil
}


// StreamTrafficStats streams real-time traffic statistics updates every 500ms.
func (s *GRPCServer) StreamTrafficStats(req *controlv1.StreamTrafficStatsRequest, stream controlv1.ControlPlane_StreamTrafficStatsServer) error {
	intervalMs := req.IntervalMs
	if intervalMs == 0 {
		intervalMs = 500
	}

	ticker := time.NewTicker(time.Duration(intervalMs) * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-stream.Context().Done():
			return nil
		case <-ticker.C:
			snapshot := s.daemon.GetTrafficSnapshot()
			update := &controlv1.TrafficStatsUpdate{
				Snapshot: &controlv1.TrafficSnapshot{
					BytesIn:           snapshot.BytesIn,
					BytesOut:          snapshot.BytesOut,
					ThroughputInBps:   snapshot.ThroughputInBPS,
					ThroughputOutBps:  snapshot.ThroughputOutBPS,
					ActiveConnections: snapshot.ActiveConnections,
					TotalConnections:  snapshot.TotalConnections,
					PacketsProcessed:  snapshot.PacketsProcessed,
				},
				TimestampUnixMs: time.Now().UnixMilli(),
			}

			if err := stream.Send(update); err != nil {
				return err
			}
		}
	}
}

// GetPrivacyStats returns aggregated privacy engine statistics.
func (s *GRPCServer) GetPrivacyStats(ctx context.Context, req *controlv1.GetPrivacyStatsRequest) (*controlv1.GetPrivacyStatsResponse, error) {
	stats := s.daemon.GetPrivacyStats()

	ttlHist := make(map[uint32]int64)
	for k, v := range stats.TTL.OriginalTTLHist {
		ttlHist[uint32(k)] = v
	}

	return &controlv1.GetPrivacyStatsResponse{
		Ttl: &controlv1.TTLNormalizationStats{
			PacketsProcessed:     stats.TTL.PacketsProcessed,
			PacketsModified:      stats.TTL.PacketsModified,
			Ipv4Packets:          stats.TTL.IPv4Packets,
			Ipv6Packets:          stats.TTL.IPv6Packets,
			OriginalTtlHistogram: ttlHist,
		},
		Fragmentation: &controlv1.FragmentationStats{
			PacketsFragmented: stats.Fragmentation.PacketsFragmented,
			FragmentsCreated:  stats.Fragmentation.FragmentsCreated,
			TlsRecordsSplit:   stats.Fragmentation.TLSRecordsSplit,
			BytesProcessed:    stats.Fragmentation.BytesProcessed,
		},
		UserAgent: &controlv1.UserAgentStats{
			RequestsProcessed: stats.UserAgent.RequestsProcessed,
			RequestsModified:  stats.UserAgent.RequestsModified,
			HeadersStripped:   stats.UserAgent.HeadersStripped,
		},
	}, nil
}

// ListPeers returns connected peer nodes.
func (s *GRPCServer) ListPeers(ctx context.Context, req *controlv1.ListPeersRequest) (*controlv1.ListPeersResponse, error) {
	peers, err := s.daemon.ListPeers(ctx)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list peers: %v", err)
	}

	protoPeers := make([]*controlv1.Peer, len(peers))
	for i, p := range peers {
		protoPeers[i] = &controlv1.Peer{
			Id:             p.ID,
			PublicKey:      p.PublicKey,
			Endpoint:       p.Endpoint,
			LastSeenUnixMs: p.LastSeen.UnixMilli(),
		}
	}

	return &controlv1.ListPeersResponse{Peers: protoPeers}, nil
}

// ConnectPeer is a stub for connecting to a peer explicitly.
func (s *GRPCServer) ConnectPeer(ctx context.Context, req *controlv1.ConnectPeerRequest) (*controlv1.ConnectPeerResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "ConnectPeer not implemented")
}

// DisconnectPeer is a stub for disconnecting from a peer.
func (s *GRPCServer) DisconnectPeer(ctx context.Context, req *controlv1.DisconnectPeerRequest) (*controlv1.DisconnectPeerResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "DisconnectPeer not implemented")
}

// === Helper Functions ===

func mapTunnelState(state TunnelState) controlv1.TunnelState {
	switch state {
	case TunnelStopped:
		return controlv1.TunnelState_TUNNEL_STATE_STOPPED
	case TunnelStarting:
		return controlv1.TunnelState_TUNNEL_STATE_STARTING
	case TunnelRunning:
		return controlv1.TunnelState_TUNNEL_STATE_RUNNING
	case TunnelDegraded:
		return controlv1.TunnelState_TUNNEL_STATE_DEGRADED
	default:
		return controlv1.TunnelState_TUNNEL_STATE_UNSPECIFIED
	}
}

func mapNodeRole(role NodeRole) controlv1.NodeRole {
	switch role {
	case RoleMaster:
		return controlv1.NodeRole_NODE_ROLE_MASTER
	case RoleClient:
		return controlv1.NodeRole_NODE_ROLE_CLIENT
	default:
		return controlv1.NodeRole_NODE_ROLE_UNSPECIFIED
	}
}

func mapProtoRole(role controlv1.NodeRole) NodeRole {
	switch role {
	case controlv1.NodeRole_NODE_ROLE_MASTER:
		return RoleMaster
	case controlv1.NodeRole_NODE_ROLE_CLIENT:
		return RoleClient
	default:
		return RoleUnspecified
	}
}

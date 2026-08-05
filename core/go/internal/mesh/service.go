package mesh

import "context"

type PeerInfo struct {
	ID        string
	PublicKey []byte
	Addrs     []string
}

type DiscoveryEvent struct {
	Peer PeerInfo
}

type Service interface {
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	Connect(ctx context.Context, peer PeerInfo) error
	Advertise(ctx context.Context, topic string) error
	Subscribe(ctx context.Context, topic string) (<-chan DiscoveryEvent, error)
}

type LibP2PConfig struct {
	ListenAddrs []string
	Bootstrap  []string
	PrivateKey []byte
}

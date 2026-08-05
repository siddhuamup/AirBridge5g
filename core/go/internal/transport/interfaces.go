package transport

import (
	"context"
	"errors"

	"github.com/example/securemesh/core/internal/protocol"
)

var ErrTransportNotStarted = errors.New("transport implementation not started")

type Endpoint struct {
	PeerID  string
	Address string
}

type Stream interface {
	ReadPacket(ctx context.Context) ([]byte, error)
	WritePacket(ctx context.Context, packet []byte) error
	Close() error
}

type Dialer interface {
	Dial(ctx context.Context, endpoint Endpoint, profile protocol.SessionProfile) (Stream, error)
}

type Listener interface {
	Listen(ctx context.Context, profile protocol.SessionProfile) (<-chan Stream, error)
}

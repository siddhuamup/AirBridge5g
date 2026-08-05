package storage

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
)

var ErrNotFound = errors.New("state record not found")

type Config struct {
	Driver string
	Path   string
}

type Peer struct {
	ID        string
	PublicKey []byte
	Endpoint  string
	LastSeen  time.Time
	Metadata  map[string]string
}

type StateStore interface {
	PutPeer(ctx context.Context, peer Peer) error
	GetPeer(ctx context.Context, id string) (Peer, error)
	ListPeers(ctx context.Context) ([]Peer, error)
	Close() error
}

func Open(ctx context.Context, cfg Config) (StateStore, error) {
	switch strings.ToLower(strings.TrimSpace(cfg.Driver)) {
	case "", "sqlite":
		return OpenSQLite(ctx, cfg.Path)
	case "badger", "badgerdb", "pebble", "pebbledb":
		return nil, fmt.Errorf("%s backend is reserved behind StateStore; SQLite is implemented in this scaffold", cfg.Driver)
	default:
		return nil, fmt.Errorf("unsupported state driver %q", cfg.Driver)
	}
}

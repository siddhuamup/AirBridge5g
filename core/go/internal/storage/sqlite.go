package storage

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	_ "modernc.org/sqlite"
)

type SQLiteStore struct {
	db *sql.DB
}

func OpenSQLite(ctx context.Context, path string) (*SQLiteStore, error) {
	if path == "" {
		path = "securemesh.db"
	}

	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}

	store := &SQLiteStore{db: db}
	if err := store.migrate(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}

	return store, nil
}

func (s *SQLiteStore) Close() error {
	return s.db.Close()
}

func (s *SQLiteStore) PutPeer(ctx context.Context, peer Peer) error {
	metadata, err := json.Marshal(peer.Metadata)
	if err != nil {
		return err
	}

	_, err = s.db.ExecContext(ctx, `
		INSERT INTO peers (id, public_key, endpoint, last_seen, metadata)
		VALUES (?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			public_key = excluded.public_key,
			endpoint = excluded.endpoint,
			last_seen = excluded.last_seen,
			metadata = excluded.metadata
	`, peer.ID, peer.PublicKey, peer.Endpoint, peer.LastSeen.UTC().Format(time.RFC3339Nano), string(metadata))
	return err
}

func (s *SQLiteStore) GetPeer(ctx context.Context, id string) (Peer, error) {
	row := s.db.QueryRowContext(ctx, `
		SELECT id, public_key, endpoint, last_seen, metadata
		FROM peers
		WHERE id = ?
	`, id)

	peer, err := scanPeer(row)
	if errors.Is(err, sql.ErrNoRows) {
		return Peer{}, ErrNotFound
	}
	return peer, err
}

func (s *SQLiteStore) ListPeers(ctx context.Context) ([]Peer, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, public_key, endpoint, last_seen, metadata
		FROM peers
		ORDER BY id
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var peers []Peer
	for rows.Next() {
		peer, err := scanPeer(rows)
		if err != nil {
			return nil, err
		}
		peers = append(peers, peer)
	}
	return peers, rows.Err()
}

func (s *SQLiteStore) migrate(ctx context.Context) error {
	_, err := s.db.ExecContext(ctx, `
		CREATE TABLE IF NOT EXISTS peers (
			id TEXT PRIMARY KEY,
			public_key BLOB NOT NULL,
			endpoint TEXT NOT NULL,
			last_seen TEXT NOT NULL,
			metadata TEXT NOT NULL DEFAULT '{}'
		)
	`)
	return err
}

type peerScanner interface {
	Scan(dest ...any) error
}

func scanPeer(scanner peerScanner) (Peer, error) {
	var peer Peer
	var lastSeen string
	var metadataRaw string

	if err := scanner.Scan(&peer.ID, &peer.PublicKey, &peer.Endpoint, &lastSeen, &metadataRaw); err != nil {
		return Peer{}, err
	}

	parsed, err := time.Parse(time.RFC3339Nano, lastSeen)
	if err != nil {
		return Peer{}, err
	}
	peer.LastSeen = parsed

	if metadataRaw == "" {
		metadataRaw = "{}"
	}
	if err := json.Unmarshal([]byte(metadataRaw), &peer.Metadata); err != nil {
		return Peer{}, err
	}
	if peer.Metadata == nil {
		peer.Metadata = map[string]string{}
	}

	return peer, nil
}

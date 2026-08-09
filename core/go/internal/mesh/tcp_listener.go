package mesh

import (
	"context"
	"encoding/hex"
	"log"
	"net"
	"time"

	"github.com/example/securemesh/core/internal/handshake"
)

// tcpListenerLoop listens for incoming mesh connections and performs the Noise handshake.
func (s *LibP2PService) tcpListenerLoop() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-mesh] panic recovered in tcpListenerLoop: %v", r)
		}
	}()
	defer s.wg.Done()

	if len(s.cfg.ListenAddrs) == 0 {
		return
	}

	tcpAddr, err := net.ResolveTCPAddr("tcp", ":0")
	if err != nil {
		log.Printf("[airbridge-mesh] resolve tcp addr error: %v", err)
		return
	}

	listener, err := net.ListenTCP("tcp", tcpAddr)
	if err != nil {
		log.Printf("[airbridge-mesh] tcp listen error: %v", err)
		return
	}

	s.tcpListener = listener
	log.Printf("[airbridge-mesh] TCP listener bound to %v", listener.Addr())

	for {
		conn, err := s.tcpListener.Accept()
		if err != nil {
			if s.ctx.Err() != nil {
				return
			}
			log.Printf("[airbridge-mesh] tcp accept error: %v", err)
			continue
		}

		go func(c net.Conn) {
			if tcpConn, ok := c.(*net.TCPConn); ok {
				tcpConn.SetKeepAlive(true)
				tcpConn.SetKeepAlivePeriod(30 * time.Second)
			}
			
			hCtx, hCancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer hCancel()

			secureConn, err := handshake.UpgradeToSecure(hCtx, c, handshake.Config{
				Initiator:     false,
				Pattern:       handshake.NoiseXX,
				AEAD:          "ChaCha20-Poly1305",
				StaticKeypair: s.noiseKeypair,
			})
			if err != nil {
				log.Printf("[airbridge-mesh] incoming handshake failed: %v", err)
				c.Close()
				return
			}

			// Handshake succeeded
			peerIDBytes := secureConn.PeerStaticKey()
			peerID := hex.EncodeToString(peerIDBytes[:min(16, len(peerIDBytes))])
			
			s.peersMu.Lock()
			if existing, ok := s.peers[peerID]; ok && existing.conn != nil {
				existing.conn.Close()
			}
			
			now := time.Now().UTC()
			s.peers[peerID] = &connectedPeer{
				info: PeerInfo{
					ID: peerID,
				},
				connectedAt: now,
				lastSeen:    now,
				conn:        secureConn,
			}
			s.stats.ConnectedPeers.Store(int64(len(s.peers)))
			s.peersMu.Unlock()

			log.Printf("[airbridge-mesh] accepted secure connection from %s", peerID)

			// Simple read loop to keep connection alive and detect disconnects
			go func() {
				buf := make([]byte, 1024)
				for {
					_, err := secureConn.Read(buf)
					if err != nil {
						s.Disconnect(peerID)
						return
					}
					s.UpdatePeerLastSeen(peerID)
				}
			}()
		}(conn)
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

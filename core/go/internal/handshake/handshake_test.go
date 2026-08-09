package handshake

import (
	"context"
	"net"
	"testing"
	"time"
)

func TestNoiseKeypairGeneration(t *testing.T) {
	kp, err := GenerateStaticKeypair()
	if err != nil {
		t.Fatalf("GenerateStaticKeypair error: %v", err)
	}
	if len(kp.Public) == 0 || len(kp.Private) == 0 {
		t.Error("expected non-empty keypair bytes")
	}
}

func TestNoiseXXHandshake(t *testing.T) {
	initKp, err := GenerateStaticKeypair()
	if err != nil {
		t.Fatalf("init keypair: %v", err)
	}
	respKp, err := GenerateStaticKeypair()
	if err != nil {
		t.Fatalf("resp keypair: %v", err)
	}

	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("net.Listen error: %v", err)
	}
	defer ln.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	errCh := make(chan error, 1)

	go func() {
		conn, err := ln.Accept()
		if err != nil {
			errCh <- err
			return
		}
		defer conn.Close()

		_, err = UpgradeToSecure(ctx, conn, Config{
			Initiator:     false,
			Pattern:       NoiseXX,
			AEAD:          "ChaCha20-Poly1305",
			StaticKeypair: respKp,
		})
		errCh <- err
	}()

	clientConn, err := net.Dial("tcp", ln.Addr().String())
	if err != nil {
		t.Fatalf("net.Dial error: %v", err)
	}
	defer clientConn.Close()

	secureClient, err := UpgradeToSecure(ctx, clientConn, Config{
		Initiator:     true,
		Pattern:       NoiseXX,
		AEAD:          "ChaCha20-Poly1305",
		StaticKeypair: initKp,
	})
	if err != nil {
		t.Fatalf("client UpgradeToSecure failed: %v", err)
	}

	serverErr := <-errCh
	if serverErr != nil {
		t.Fatalf("server UpgradeToSecure failed: %v", serverErr)
	}

	if len(secureClient.PeerStaticKey()) == 0 {
		t.Error("expected non-empty peer static key after handshake")
	}
}

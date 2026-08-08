package main

import (
	"context"
	"fmt"
	"log"
	"os/signal"
	"runtime"
	"syscall"
	"time"

	"github.com/example/securemesh/core/internal/config"
	"github.com/example/securemesh/core/internal/mesh"
	"github.com/example/securemesh/core/internal/observability"
	"github.com/example/securemesh/core/internal/platform"
	"github.com/example/securemesh/core/internal/privacy"
	"github.com/example/securemesh/core/internal/protocol"
	"github.com/example/securemesh/core/internal/proxy"
	"github.com/example/securemesh/core/internal/security"
	"github.com/example/securemesh/core/internal/services"
	"github.com/example/securemesh/core/internal/storage"
	"go.opentelemetry.io/otel"
)

const (
	version   = "1.0.0-alpha"
	banner    = `
    ___    _      ____       _     __            ________ 
   /   |  (_)____/ __ )_____(_)___/ /___ ____   / ____/ /_
  / /| | / / ___/ __  / ___/ / __  / __  / _ \ /___ \/ __/
 / ___ |/ / /  / /_/ / /  / / /_/ / /_/ /  __/____/ / /_  
/_/  |_/_/_/  /_____/_/  /_/\__,_/\__, /\___/_____/\__, / 
                                 /____/           /____/  
    Cross-Platform Network Resilience Utility
`
)

func main() {
	fmt.Print(banner)
	fmt.Printf("  Version: %s | Platform: %s/%s\n\n", version, runtime.GOOS, runtime.GOARCH)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg := config.LoadFromEnv()

	// === Observability Setup ===
	shutdownTracing, err := observability.Setup(ctx, cfg.Tracing)
	if err != nil {
		log.Fatalf("[airbridge] setup tracing: %v", err)
	}
	defer func() {
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := shutdownTracing(shutdownCtx); err != nil {
			log.Printf("[airbridge] shutdown tracing: %v", err)
		}
	}()

	tracer := otel.Tracer("airbridge-5g")
	ctx, span := tracer.Start(ctx, "daemon.bootstrap")
	defer span.End()

	// === Platform Detection ===
	plat := platform.Detect()
	log.Printf("[airbridge] platform detected: %s (mobile=%v, desktop=%v)",
		plat, plat.IsMobile(), plat.IsDesktop())

	// === State Store ===
	state, err := storage.Open(ctx, cfg.Storage)
	if err != nil {
		log.Fatalf("[airbridge] open state store: %v", err)
	}
	defer func() {
		if err := state.Close(); err != nil {
			log.Printf("[airbridge] close state store: %v", err)
		}
	}()

	// === Protocol Negotiation ===
	serverCaps := protocol.DefaultCapabilities()
	clientCaps := protocol.Capabilities{
		AEADSuites:     []protocol.AEADSuite{protocol.AEADChaCha20Poly1305, protocol.AEADAES256GCM},
		Transports:     []protocol.Transport{protocol.TransportQUIC, protocol.TransportSOCKS5TLS},
		HandshakeModes: []protocol.NoisePattern{protocol.NoiseIK, protocol.NoiseXX},
		ProtocolVersion: "securemesh/1",
	}
	profile, err := protocol.NegotiateCapabilities(serverCaps, clientCaps)
	if err != nil {
		log.Fatalf("[airbridge] negotiate defaults: %v", err)
	}
	log.Printf("[airbridge] session profile: %s over %s with %s",
		profile.NoisePattern, profile.Transport, profile.AEAD)

	// === Privacy Engine ===
	ttlNorm, err := privacy.NewTTLNormalizer(privacy.DefaultTTLConfig())
	if err != nil {
		log.Fatalf("[airbridge] init TTL normalizer: %v", err)
	}

	fragmenter, err := privacy.NewFragmenter(privacy.DefaultFragmenterConfig())
	if err != nil {
		log.Fatalf("[airbridge] init fragmenter: %v", err)
	}

	uaHarmonizer := privacy.NewUAHarmonizer(privacy.DefaultUAHarmonizerConfig())

	log.Printf("[airbridge] privacy engine initialized (TTL target=%d, fragment strategy=random)",
		privacy.DefaultTargetTTL)

	// === Daemon (Control Plane) ===
	daemonCfg := services.DefaultDaemonConfig()
	daemonCfg.NodeID = cfg.NodeID
	daemonCfg.Version = version

	// === Security & Kill Switch ===
	killSwitch := security.NewKillSwitch(daemonCfg.ProxyAddress, daemonCfg.GRPCAddress)
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[airbridge-security] panic recovered during shutdown: %v", r)
		}
		_ = killSwitch.Disable()
	}()

	// === SOCKS5 Proxy Server ===
	proxyCfg := proxy.DefaultServerConfig()
	// Dynamic token authenticator — populated via QR credential exchange at runtime
	proxyCfg.Auth = proxy.NewTokenAuthenticator(make(map[string]string))
	proxyServer := proxy.NewServer(proxyCfg)

	// === Mesh Network ===
	meshCfg := mesh.LibP2PConfig{
		ListenAddrs: []string{"/ip4/0.0.0.0/tcp/0"},
	}
	meshService, err := mesh.NewLibP2PService(meshCfg)
	if err != nil {
		log.Fatalf("[airbridge] init mesh: %v", err)
	}

	daemon := services.NewDaemon(
		daemonCfg,
		proxyServer,
		meshService,
		ttlNorm,
		fragmenter,
		uaHarmonizer,
		state,
	)

	if err := daemon.Start(ctx); err != nil {
		log.Fatalf("[airbridge] daemon start: %v", err)
	}
	defer func() {
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := daemon.Stop(shutdownCtx); err != nil {
			log.Printf("[airbridge] daemon stop: %v", err)
		}
	}()

	// === gRPC Server ===
	grpcServer := services.NewGRPCServer(daemon, daemonCfg.GRPCAddress)
	if err := grpcServer.Start(ctx); err != nil {
		log.Fatalf("[airbridge] gRPC server start: %v", err)
	}
	defer grpcServer.Stop()

	// === Status Report ===
	status, err := daemon.Status(ctx)
	if err != nil {
		log.Printf("[airbridge] status: %v", err)
	} else {
		fmt.Printf("\n  ✓ AirBridge 5G daemon ready\n")
		fmt.Printf("    Node ID:     %s\n", status.NodeID)
		fmt.Printf("    State:       %s\n", status.TunnelState)
		fmt.Printf("    Mesh Node:   %s\n", meshService.NodeID())
		fmt.Printf("    Proxy:       %s\n", proxyCfg.BindAddress)
		fmt.Printf("    gRPC Server: %s\n", daemonCfg.GRPCAddress)
		fmt.Printf("    Platform:    %s\n", plat)
		fmt.Printf("    State DB:    %s (%s)\n\n", cfg.Storage.Path, cfg.Storage.Driver)
	}

	fmt.Println("  Press Ctrl+C to stop the daemon.")
	<-ctx.Done()
	fmt.Println("\n  Shutting down gracefully...")
}


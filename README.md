# AirBridge 5G

> Cross-Platform Network Resilience & Connectivity Utility

AirBridge 5G is a privacy-first, peer-to-peer network sharing application that enables mobile devices to securely share their internet connectivity with desktop and other mobile devices through an encrypted mesh network.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Frontend                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │   Home   │  │  Master  │  │  Client  │  │   Settings   │   │
│  │  Screen  │  │Dashboard │  │Dashboard │  │    Screen    │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│  ┌──────────────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │   Diagnostics    │  │   Analytics   │  │   OTA Updates    │ │
│  └──────────────────┘  └───────────────┘  └──────────────────┘ │
│                           │                                     │
│                    Riverpod State                                │
│            ┌──────────────┼──────────────┐                      │
│            │              │              │                       │
│     roleProvider   settingsProvider  daemonProvider              │
│                           │                                     │
│                     gRPC Client                                 │
└───────────────────────────┼─────────────────────────────────────┘
                            │ gRPC (protobuf)
┌───────────────────────────┼─────────────────────────────────────┐
│                     Go Daemon Core                              │
│                           │                                     │
│  ┌────────────────────────┼────────────────────────────────┐   │
│  │                   Daemon Service                         │   │
│  │   (orchestrates all subsystems, gRPC server)            │   │
│  └────────────────────────┼────────────────────────────────┘   │
│            ┌──────────────┼──────────────┐                      │
│            │              │              │                       │
│  ┌─────────▼──┐  ┌───────▼────┐  ┌──────▼──────┐              │
│  │   SOCKS5   │  │    Mesh    │  │   Privacy   │              │
│  │   Proxy    │  │  (LibP2P)  │  │   Engine    │              │
│  │  Server    │  │            │  │             │              │
│  │            │  │ ┌────────┐ │  │ ┌─────────┐ │              │
│  │ ┌────────┐ │  │ │ Gossip │ │  │ │   TTL   │ │              │
│  │ │Fragment│ │  │ │  UDP   │ │  │ │ Normalz │ │              │
│  │ │ Writer │ │  │ └────────┘ │  │ └─────────┘ │              │
│  │ └────────┘ │  │ ┌────────┐ │  │ ┌─────────┐ │              │
│  │ ┌────────┐ │  │ │  NAT   │ │  │ │   UA    │ │              │
│  │ │  UA    │ │  │ │Travers │ │  │ │Harmoniz│ │              │
│  │ │Harmonz│ │  │ │ (STUN) │ │  │ └─────────┘ │              │
│  │ └────────┘ │  │ └────────┘ │  │ ┌─────────┐ │              │
│  │ ┌────────┐ │  │ ┌────────┐ │  │ │   DPI   │ │              │
│  │ │  Rate  │ │  │ │  Peer  │ │  │ │Fragment │ │              │
│  │ │Limiter │ │  │ │Manager │ │  │ └─────────┘ │              │
│  │ └────────┘ │  │ └────────┘ │  └─────────────┘              │
│  └────────────┘  └────────────┘                                 │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│  │   QUIC      │  │   Noise     │  │   Observability     │    │
│  │  Transport  │  │  Handshake  │  │   (OpenTelemetry)   │    │
│  │ (TLS 1.3)  │  │  (IK/XX)   │  │                     │    │
│  └─────────────┘  └─────────────┘  └─────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Features

### Core
- **SOCKS5 Proxy Server** — RFC 1928/1929 compliant with username/password auth
- **Mesh Networking** — P2P peer discovery via UDP gossip protocol
- **Privacy Engine** — TTL normalization, DPI-resilient packet fragmentation, User-Agent harmonization
- **Noise Protocol** — End-to-end encrypted connections using Noise IK/XX handshakes
- **QUIC Transport** — Multiplexed, low-latency transport with TLS 1.3
- **NAT Traversal** — STUN-based reflexive address discovery and UDP hole punching

### Flutter App
- **Polymorphic UI** — Role-based UI morphing (Master/Client modes)
- **Cross-Platform** — Windows (Fluent UI), macOS/iOS (Cupertino), Android/Linux (Material)
- **QR Code Pairing** — Scan-to-connect with auto-rotation (24h)
- **Real-time Dashboard** — Traffic graphs, peer counts, latency monitoring
- **Settings Persistence** — All settings saved via SharedPreferences
- **Dark Mode Toggle** — Instant theme switching
- **Multi-language** — English, Hindi, Marathi, Spanish, French, German, Japanese, Chinese, Arabic, Portuguese
- **Network Diagnostics** — Built-in ping, traceroute, DNS lookup, port scanning
- **Analytics** — Usage stats with hourly traffic charts
- **OTA Updates** — GitHub Releases-based update checking
- **Crash Recovery** — `runZonedGuarded` + `ErrorWidget.builder` for graceful error handling

### Platform Integration
| Platform | Network Control Method |
|----------|----------------------|
| Windows  | WinINet API (system proxy) |
| macOS    | `networksetup` CLI (SOCKS proxy) |
| Linux    | `gsettings` (GNOME) / `kwriteconfig5` (KDE) |
| Android  | `VpnService` + `ProxyInfo` + TUN interface |
| iOS      | `NEProxySettings` + `NETunnelProviderManager` |

## Project Structure

```
AirBridge5g/
├── apps/airbridge_5g/          # Flutter application
│   ├── lib/
│   │   ├── main.dart           # Entry point (crash recovery)
│   │   ├── app.dart            # Root widget (platform-adaptive)
│   │   ├── features/
│   │   │   ├── home/           # Role selection screen
│   │   │   ├── master/         # Master dashboard + QR rotation
│   │   │   ├── client/         # Client dashboard
│   │   │   ├── settings/       # Persisted settings
│   │   │   ├── diagnostics/    # Network diagnostics
│   │   │   └── analytics/      # Usage statistics
│   │   ├── providers/
│   │   │   ├── role_provider.dart      # Node role state
│   │   │   ├── settings_provider.dart  # SharedPreferences persistence
│   │   │   ├── theme_provider.dart     # Dark mode state
│   │   │   └── daemon_provider.dart    # gRPC client provider
│   │   ├── routing/
│   │   │   └── app_router.dart         # GoRouter (deep linking)
│   │   ├── services/
│   │   │   ├── platform_vpn.dart       # Cross-platform proxy manager
│   │   │   ├── windows_proxy.dart      # Windows WinINet
│   │   │   ├── macos_proxy.dart        # macOS networksetup
│   │   │   ├── linux_proxy.dart        # Linux gsettings/KDE
│   │   │   ├── android_vpn.dart        # Android VpnService bridge
│   │   │   ├── ios_vpn.dart            # iOS NetworkExtension bridge
│   │   │   ├── ota_update.dart         # OTA update checker
│   │   │   └── grpc_daemon_client.dart # gRPC client
│   │   └── ui/                 # Shared UI components
│   ├── android/
│   │   └── app/src/main/kotlin/
│   │       └── com/airbridge/airbridge_5g/
│   │           ├── AirBridgeVpnService.kt     # Native Android VPN
│   │           └── VpnMethodChannelHandler.kt  # Flutter bridge
│   └── ios/Runner/
│       └── VpnMethodChannelHandler.swift       # Native iOS VPN
│
├── core/go/                    # Go daemon backend
│   ├── cmd/securemesh-node/    # CLI entry point
│   └── internal/
│       ├── proxy/
│       │   ├── socks5.go       # SOCKS5 proxy server
│       │   └── rate_limiter.go # QoS bandwidth control
│       ├── mesh/
│       │   ├── libp2p.go       # P2P networking + gossip protocol
│       │   ├── nat_traversal.go # STUN client + hole punching
│       │   └── peer_manager.go # Kick/block/trust management
│       ├── handshake/
│       │   ├── noise.go        # Noise protocol config
│       │   └── noise_conn.go   # Socket-level Noise encryption
│       ├── transport/
│       │   ├── quic.go         # QUIC transport (TLS 1.3)
│       │   └── interfaces.go   # Transport interfaces
│       ├── privacy/            # TTL, UA harmonizer, fragmenter
│       ├── services/           # Daemon orchestrator + gRPC server
│       └── observability/      # OpenTelemetry tracing
│
├── proto/                      # Protobuf definitions
└── docs/                       # Additional documentation
```

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.4.0
- Go ≥ 1.25.0
- Protobuf compiler (`protoc`) — optional, pre-generated files included

### Build & Run

```bash
# Flutter app
cd apps/airbridge_5g
flutter pub get
flutter run

# Go daemon
cd core/go
go build -o securemesh-node ./cmd/securemesh-node
./securemesh-node
```

### Android Setup
1. The `AirBridgeVpnService` requires `android.permission.BIND_VPN_SERVICE` in `AndroidManifest.xml`
2. User will be prompted for VPN permission on first connect

### iOS Setup
1. Add `NetworkExtension` capability to the app target
2. Create a Network Extension target with `NEPacketTunnelProvider`
3. Configure the `com.airbridge.airbridge5g.tunnel` bundle identifier

## API Reference

### gRPC Services
| Service | Method | Description |
|---------|--------|-------------|
| `DaemonService` | `GetStatus` | Returns daemon health, uptime, active connections |
| `DaemonService` | `StartProxy` | Starts the SOCKS5 proxy on specified port |
| `DaemonService` | `StopProxy` | Gracefully stops the proxy |
| `DaemonService` | `ListPeers` | Lists connected mesh peers |
| `DaemonService` | `SetPrivacyConfig` | Updates TTL/DPI/UA privacy settings |
| `DaemonService` | `GetTrafficSnapshot` | Returns traffic metrics snapshot |
| `DaemonService` | `GenerateCredentials` | Generates new QR auth credentials |

### Privacy Engine
| Feature | Layer | Implementation |
|---------|-------|---------------|
| TTL Normalization | L3 (best-effort) | `setsockopt(IP_TTL, 64)` on outbound socket |
| Packet Fragmentation | L5 | `fragmentingWriter` in relay loop |
| UA Harmonization | L7 (HTTP only) | `uaHarmonizingReader` inspects first bytes |
| DNS-over-HTTPS | L7 | Configurable DoH resolver |

## Security

- **Encryption**: Noise Protocol Framework (IK/XX patterns) with ChaCha20-Poly1305 or AES-256-GCM
- **Key Exchange**: Curve25519 Diffie-Hellman
- **Transport**: TLS 1.3 with ALPN `airbridge/1`
- **Auth**: SOCKS5 username/password (RFC 1929) + QR-based credential exchange
- **QR Rotation**: Automatic 24-hour credential rotation

## License

MIT License — see [LICENSE](LICENSE) for details.

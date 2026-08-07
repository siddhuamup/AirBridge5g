# PROJECT_MEMORY.md — AirBridge 5G System & Context Memory

## 1. Confirmed Technology Stack

| Layer | Technology Choice |
| --- | --- |
| **UI** | Flutter 3.22 + Riverpod + GoRouter + FL Chart + mobile_scanner + qr_flutter |
| **Core Engine** | Go 1.22+ control plane & protocol engine |
| **Control Bridge** | gRPC (proto3) service contracts (`airbridge.control.v1.ControlPlane`) on `127.0.0.1:50051` |
| **Protocol** | QUIC + SOCKS5 over TLS 1.3 |
| **Mesh Networking** | libp2p adapter with mDNS LAN discovery |
| **Security & Crypto** | Noise Protocol Framework (X25519, IK/XX handshakes), ChaCha20-Poly1305, mTLS, Network Lock Kill Switch |
| **Native Integrations** | Android VpnService, iOS NetworkExtension, Windows WinINet Proxy |
| **CI/CD** | GitHub Actions (`.github/workflows/ci.yml`) |
| **Persistent State** | SQLite (`modernc.org/sqlite` pure Go driver) |

---

## 2. Monorepo Layout

```text
apps/airbridge_5g/              Flutter 3.22 mobile & desktop client shell
├── lib/
│   ├── features/               Master, Client, Home, Settings screens
│   ├── generated/              Generated Protobuf Dart stubs (control.pb.dart, etc.)
│   ├── providers/              Riverpod providers (role_provider, daemon_provider, theme_provider)
│   ├── services/               gRPC client, Windows proxy, Mobile VPN, unified platform network manager
│   └── utils/                  Crypto & QR credential utilities
├── android/                    Android native VpnService & MainActivity Kotlin entry points
├── windows/                    Windows native WinINet proxy C++ implementation
└── ios/                        iOS NetworkExtension AppDelegate Swift entry points
core/go/                        Go 1.22 control plane & protocol engine
├── cmd/securemesh-node/        Go daemon entry point
├── internal/                   Services, SOCKS5 proxy, Privacy engine (TTL, fragment, UA), Security (KillSwitch)
proto/control/v1/               gRPC / Protobuf service contracts (`control.proto`)
docs/                           Architecture, User Guide (`USER_GUIDE.md`)
```

---

## 3. Database Schema

### Table: `peers`
```sql
CREATE TABLE IF NOT EXISTS peers (
    id TEXT PRIMARY KEY,
    public_key BLOB NOT NULL,
    endpoint TEXT NOT NULL,
    last_seen TEXT NOT NULL,         -- RFC3339Nano UTC format
    metadata TEXT NOT NULL DEFAULT '{}' -- JSON string key-value map
);
```

---

## 4. API Contracts (`proto/control/v1/control.proto`)

Package: `airbridge.control.v1`  
Service: `ControlPlane` (14 RPC Methods: `GetStatus`, `StartTunnel`, `StopTunnel`, `SetRole`, `GetRole`, `GenerateQRCredentials`, `ImportQRCredentials`, `GetTrafficStats`, `StreamTrafficStats`, `GetPrivacyStats`, `ListPeers`, `ConnectPeer`, `DisconnectPeer`)

---

## 5. Key Architecture & Resolution Learnings

1. **`NodeRole` Type Name Collision**:
   - *Problem*: `grpc_daemon_client.dart` imported both Riverpod's `NodeRole` enum and protobuf's generated `NodeRole` class.
   - *Solution*: Aliased generated Dart protobuf imports (`import '../generated/control.pbenum.dart' as pbenum;`) to disambiguate.

2. **Network Lock (Kill Switch)**:
   - *Problem*: Tunnel disruptions can leak unencrypted IP traffic outside SOCKS5 proxy.
   - *Solution*: Built `KillSwitch` (`internal/security/killswitch.go`) invoking OS firewall commands (`netsh advfirewall`, `iptables`, `pfctl`) to block non-tunnel egress during failure states.

3. **gRPC Client Resiliency**:
   - *Problem*: Daemon startup timing or transient network delays causing RPC drops.
   - *Solution*: Wrapped all Dart client calls in `_retryCall` with exponential backoff (500ms → 1s → 2s, max 3 retries).

4. **Pure Go SQLite Driver (`modernc.org/sqlite`)**:
   - *Solution*: Uses CGO-free `modernc.org/sqlite` driver for zero-CGO cross-platform compilation.

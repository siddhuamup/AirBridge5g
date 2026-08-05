# PROJECT_MEMORY.md — SecureMesh System & Context Memory

## 1. Confirmed Technology Stack

| Layer | Technology Choice |
| --- | --- |
| **UI** | Flutter 3.22 + Riverpod + GoRouter |
| **Core Engine** | Go 1.22 (primary control plane) + Rust FFI (hot paths) |
| **Protocol** | QUIC + SOCKS5 over TLS 1.3 |
| **Mesh Networking** | libp2p adapter boundary |
| **Security & Crypto** | AES-256-GCM + ChaCha20-Poly1305 (Runtime Negotiation), Noise Protocol Framework (X25519, IK/XX handshakes), mTLS |
| **Native Integrations** | Android VpnService, iOS NetworkExtension, Windows WinTun |
| **CI/CD** | GitHub Actions + Codemagic |
| **Observability** | Prometheus + Grafana + Loki (Self-Hosted), OpenTelemetry for distributed tracing |
| **Persistent State** | SQLite (`modernc.org/sqlite` pure Go driver) with adapter points for BadgerDB/PebbleDB |
| **Internal RPC Interfaces** | gRPC (proto3) service contracts (`securemesh.control.v1`) |

---

## 2. Monorepo Layout

```text
apps/flutter_securemesh/        Flutter 3.22 mobile & desktop client shell
core/go/                        Go 1.22 control plane & protocol engine
core/rust/securemesh_hotpath/   Rust cdylib for FFI hot path optimizations
native/                         Platform integration notes & VPN entry points
observability/                  Prometheus, Grafana, Loki, OpenTelemetry configs
proto/control/v1/               gRPC / Protobuf service contracts
docs/                           Architecture, security, and protocol design notes
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

#### Go Storage Model (`internal/storage/store.go` & `sqlite.go`)
```go
type Peer struct {
    ID        string            `json:"id"`
    PublicKey []byte            `json:"public_key"`
    Endpoint  string            `json:"endpoint"`
    LastSeen  time.Time         `json:"last_seen"`
    Metadata  map[string]string `json:"metadata"`
}
```

---

## 4. API Contracts (`proto/control/v1/control.proto`)

Package: `securemesh.control.v1`  
Service: `ControlPlane`

```protobuf
service ControlPlane {
  rpc GetStatus(GetStatusRequest) returns (GetStatusResponse);
  rpc StartTunnel(StartTunnelRequest) returns (StartTunnelResponse);
  rpc StopTunnel(StopTunnelRequest) returns (StopTunnelResponse);
  rpc ListPeers(ListPeersRequest) returns (ListPeersResponse);
}

message GetStatusRequest {}

message GetStatusResponse {
  string node_id = 1;
  string tunnel_state = 2;
  uint32 connected_peers = 3;
  int64 started_at_unix_ms = 4;
}

message StartTunnelRequest {}
message StartTunnelResponse {
  string state = 1;
}

message StopTunnelRequest {}
message StopTunnelResponse {
  string state = 1;
}

message ListPeersRequest {}
message ListPeersResponse {
  repeated Peer peers = 1;
}

message Peer {
  string id = 1;
  bytes public_key = 2;
  string endpoint = 3;
  int64 last_seen_unix_ms = 4;
}
```

---

## 5. Resolved Bugs & Key Implementation Learnings

1. **Pure Go SQLite Driver (`modernc.org/sqlite`)**:
   - *Problem*: Traditional `mattn/go-sqlite3` requires CGO, enabling cross-compilation friction for Android/Windows targets.
   - *Solution*: Uses CGO-free `modernc.org/sqlite` driver with explicit RFC3339Nano string encoding for timestamps and JSON string fallback (`{}`) for peer metadata map scanning.

2. **Noise Handshake Boundaries (IK vs. XX)**:
   - *Problem*: Pre-shared static keys vs first-contact dynamic peer exchanges.
   - *Solution*: Noise IK pattern enforced for known static peer public key verification; Noise XX fallbacks for initial discovery contact.

3. **Runtime AEAD Negotiation**:
   - *Problem*: Heterogeneous client hardware capabilities (AES-NI hardware acceleration vs ARM Neon ChaCha20-Poly1305).
   - *Solution*: Dynamic runtime cipher negotiation supporting both AES-256-GCM and ChaCha20-Poly1305 based on client capability flags.

4. **PowerShell Argument Escaping in Windows Installer Wrappers**:
   - *Problem*: Trailing backslashes (`\`) before quotes in PowerShell inline command invocations cause syntax string termination errors (`TerminatorExpectedAtEndOfString`).
   - *Solution*: Stripped trailing backslashes or sanitized quotes in script paths when issuing commands via PowerShell CLI.

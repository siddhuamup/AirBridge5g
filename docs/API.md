# AirBridge 5G — API Documentation

## gRPC API

The Go daemon exposes a gRPC server (default port `:50051`) for Flutter app communication.

### Service: `DaemonService`

#### `GetStatus`
Returns the daemon's health, uptime, active connection count, and transport info.

**Request**: `StatusRequest` (empty)  
**Response**:
```protobuf
message StatusResponse {
  bool running = 1;
  int64 uptime_seconds = 2;
  int32 active_connections = 3;
  string proxy_address = 4;
  string transport_type = 5;
}
```

---

#### `StartProxy`
Starts the SOCKS5 proxy server on the specified address.

**Request**:
```protobuf
message StartProxyRequest {
  string bind_address = 1; // e.g., "0.0.0.0:1080"
  string username = 2;     // SOCKS5 auth username
  string password = 3;     // SOCKS5 auth password
}
```
**Response**: `StartProxyResponse { bool success = 1; string error = 2; }`

---

#### `StopProxy`
Gracefully stops the proxy, draining active connections.

**Request**: `StopProxyRequest` (empty)  
**Response**: `StopProxyResponse { bool success = 1; }`

---

#### `ListPeers`
Returns all connected mesh peers with their connection info.

**Response**:
```protobuf
message ListPeersResponse {
  repeated PeerInfo peers = 1;
}

message PeerInfo {
  string id = 1;
  string address = 2;
  int64 connected_since = 3;
  int64 bytes_sent = 4;
  int64 bytes_received = 5;
  int32 latency_ms = 6;
}
```

---

#### `SetPrivacyConfig`
Updates the privacy engine configuration at runtime.

**Request**:
```protobuf
message PrivacyConfigRequest {
  bool doh_enabled = 1;
  bool kill_switch_enabled = 2;
  bool ttl_enabled = 3;
  bool fragmenter_enabled = 4;
  bool ua_harmonize_enabled = 5;
}
```

---

#### `GetTrafficSnapshot`
Returns current traffic metrics.

**Response**:
```protobuf
message TrafficSnapshot {
  int64 bytes_in = 1;
  int64 bytes_out = 2;
  int64 active_connections = 3;
  int64 total_connections = 4;
  int64 auth_failures = 5;
}
```

---

#### `GenerateCredentials`
Generates new SOCKS5 authentication credentials for QR sharing.

**Response**:
```protobuf
message CredentialsResponse {
  string username = 1;
  string password = 2;
  string proxy_address = 3;
  int64 expires_at = 4; // Unix timestamp
}
```

---

## Flutter Platform Channels

### `com.airbridge/vpn` (Android)
| Method | Args | Returns | Description |
|--------|------|---------|-------------|
| `startVpn` | `{proxy_host: String, proxy_port: int}` | `bool` | Starts Android VpnService |
| `stopVpn` | — | `bool` | Stops VPN tunnel |
| `isVpnActive` | — | `bool` | Checks VPN status |

### `com.airbridge/ios_vpn` (iOS)
| Method | Args | Returns | Description |
|--------|------|---------|-------------|
| `startVpn` | `{proxy_host: String, proxy_port: int}` | `bool` | Starts iOS NEPacketTunnel |
| `stopVpn` | — | `bool` | Stops VPN tunnel |
| `isVpnActive` | — | `bool` | Checks VPN status |

### `com.airbridge/windows_proxy` (Windows)
| Method | Args | Returns | Description |
|--------|------|---------|-------------|
| `setProxy` | `{proxyAddress: String}` | `bool` | Sets WinINet SOCKS proxy |
| `disableProxy` | — | `bool` | Disables system proxy |
| `isProxyActive` | — | `bool` | Checks proxy status |

---

## Deep Linking

The app supports deep links for automatic peer connection:

| URI | Action |
|-----|--------|
| `airbridge://connect?host=192.168.1.5&port=1080` | Opens client mode and auto-connects |
| `airbridge://settings` | Opens settings screen |
| `airbridge://diagnostics` | Opens network diagnostics |

---

## Noise Protocol Handshake

### Supported Patterns
- **Noise_IK**: 1-RTT (requires known peer static key)
- **Noise_XX**: 1.5-RTT (mutual authentication, no prior knowledge)

### Cipher Suites
- `Curve25519` + `ChaChaPoly` + `BLAKE2s` (default)
- `Curve25519` + `AESGCM` + `BLAKE2s` (alternative)

### Wire Format
After handshake, all data is framed as:
```
[2 bytes: payload length (big-endian)] [N bytes: encrypted payload]
```

---

## NAT Traversal

### STUN Discovery
Default servers: `stun.l.google.com:19302`, `stun1.l.google.com:19302`, `stun.cloudflare.com:3478`

### Detected NAT Types
| Type | Traversal |
|------|-----------|
| No NAT (Public IP) | Direct connection |
| Full Cone | UDP hole punch |
| Restricted Cone | UDP hole punch (requires coordination) |
| Port-Restricted | UDP hole punch (harder, may need TURN) |
| Symmetric | TURN relay required |

### Hole Punching Protocol
1. Both peers discover reflexive addresses via STUN
2. Exchange addresses via signaling (mesh gossip or QR)
3. Both send `AIRBRIDGE_PUNCH` packets simultaneously
4. First successful reply establishes the connection

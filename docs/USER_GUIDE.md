# 📖 AirBridge 5G — Enterprise User & Operator Guide

AirBridge 5G is a cross-platform network resilience utility designed to provide encrypted local data sharing, connection failover, and traffic privacy preservation.

---

## 🚀 Quick Start Guide

### 1. Master Mode (Connection Provider)
1. Launch the **AirBridge 5G** application.
2. Select **Provide Data (Master Mode)** from the home screen.
3. The **Master Dashboard** will display:
   - A unique, encrypted **QR Code payload**.
   - Real-time **Upload/Download throughput graphs**.
   - Connected client devices with individual bandwidth metrics.
4. Keep the Master node running. The Go backend proxy (`127.0.0.1:1080`) and control plane (`127.0.0.1:50051`) will operate autonomously.

### 2. Client Mode (Connection Consumer)
1. Launch **AirBridge 5G** on the client device (Android, iOS, or Windows).
2. Select **Consume Data (Client Mode)**.
3. Point the built-in **QR Scanner** at the Master device's screen.
4. The client will automatically negotiate authentication keys, establish QUIC transport, and route system traffic through the Master's cellular connection.

---

## 🔒 Security & Privacy Architecture

- **End-to-End Encryption**: Noise_IK protocol over QUIC with ChaCha20-Poly1305 authentication.
- **TTL Normalization**: All outbound IP packets have their Time-To-Live (TTL) normalized to `64` (mobile standard) to hide device topology.
- **Packet Fragmentation**: TLS ClientHello records and TCP segments are dynamically fragmented into random sizes (100–400 bytes) to prevent DPI finger-printing.
- **User-Agent Harmonization**: Desktop OS headers are sanitized and harmonized to mobile signatures.
- **Network Lock (Kill Switch)**: OS firewall rules (`netsh` / `iptables` / `pfctl`) block unencrypted traffic if the tunnel disconnects unexpectedly.

---

## 🛠️ Operational Diagnostics & Troubleshooting

| Issue | Cause | Solution |
|:---|:---|:---|
| **Daemon Offline** | Control plane port `:50051` blocked or process terminated | Restart `securemesh-node` binary or ensure no conflicting process occupies port `50051`. |
| **QR Code Expired** | Session token exceeded 24-hour lifetime | Click **Regenerate** on the Master Dashboard to issue fresh credentials. |
| **VPN Permission Prompt** | First-time launch on Android/iOS | Grant the system `VpnService` permission when prompted to enable traffic routing. |
| **Proxy Not Setting on Windows** | Insufficient WinINet privileges | Run AirBridge 5G or allow network proxy configuration in Windows Settings. |

---

## 📊 System Requirements

- **Android**: 8.0 (API 26) or higher
- **iOS**: 14.0 or higher
- **Windows**: Windows 10 / 11 (64-bit)
- **Go Daemon**: Architecture-native binary (`amd64`, `arm64`) using <150MB RAM.

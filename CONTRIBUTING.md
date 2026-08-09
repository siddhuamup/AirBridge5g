# Contributing to AirBridge 5G

Thank you for your interest in contributing to **AirBridge 5G** — a decentralized, high-throughput, privacy-focused P2P mesh proxy and VPN solution.

## Architecture Overview

AirBridge 5G is composed of two primary components:
1. **Core Go Daemon (`core/go`)**: Control plane, NoiseXX encrypted P2P mesh networking, gRPC control server, SOCKS5 proxy, QUIC streams, DNS-over-HTTPS (DoH), and privacy normalization.
2. **Flutter Multiplatform App (`apps/airbridge_5g`)**: Modern UI dashboard supporting Android, iOS, Windows, macOS, and Web with native VPN integrations (`Tun2Socks.kt` for Android, `PacketTunnelProvider.swift` for iOS).

```
+-----------------------------------------------------------+
|                   Flutter UI App                          |
|    (Dashboard, Settings, Diagnostics, OTA Updates)        |
+-----------------------------+-----------------------------+
                              | gRPC (Control Plane)
+-----------------------------v-----------------------------+
|                     Core Go Daemon                        |
|  +------------------+  +-------------------+  +---------+  |
|  |  SOCKS5 Proxy    |  | NoiseXX P2P Mesh  |  |  QUIC   |  |
|  +------------------+  +-------------------+  +---------+  |
+-----------------------------+-----------------------------+
                              | Native TUN (VPN)
+-----------------------------v-----------------------------+
|    Android Tun2Socks / iOS PacketTunnelProvider           |
+-----------------------------------------------------------+
```

## Development Setup

### Prerequisites
- **Go 1.21+**
- **Flutter 3.19+**
- **Android SDK & NDK** (for Android builds)
- **Xcode 15+** (for iOS builds)

### Running the Go Backend
```bash
cd core/go
go test ./...
go run ./cmd/securemesh-node
```

### Running the Flutter Client
```bash
cd apps/airbridge_5g
flutter pub get
flutter test
flutter run -d windows # Or android, ios, macos, chrome
```

## Code Style & Guidelines
- **Go**: Follow standard `gofmt` style. Ensure all public functions have doc comments.
- **Dart/Flutter**: Use Riverpod for state management. Ensure standard `flutter analyze` passes without warnings.
- **Kotlin/Swift**: Follow platform conventions for native VPN packet handling and IPC channels.

## Submitting Pull Requests
1. Fork the repository and create a feature branch (`git checkout -b feature/amazing-feature`).
2. Write unit tests for new functionality in `core/go` or `apps/airbridge_5g/test`.
3. Ensure all automated tests pass (`go test ./...`).
4. Submit a Pull Request with a detailed summary of changes.

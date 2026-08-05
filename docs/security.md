# Security Model

## Handshake

SecureMesh uses the Noise Protocol Framework for authenticated key exchange:

- Use Noise IK when the remote peer static public key is already trusted.
- Use Noise XX for first contact or bootstrap flows where identity is learned during the handshake.
- Bind protocol negotiation data into the Noise prologue so downgraded capabilities are detectable.

## Ciphers

Sessions negotiate an AEAD at runtime:

- `AES-256-GCM` is preferred when hardware acceleration is available.
- `ChaCha20-Poly1305` is preferred for mobile and software-only environments.

Both ciphers use 256-bit keys. Nonce ownership must stay per-direction and per-session; never reuse a nonce/key pair.

## Transport authentication

QUIC and SOCKS5-over-TLS use TLS 1.3 with mutual certificate authentication. Noise authenticates peer session keys; mTLS authenticates transport endpoints and can be rotated independently.

## Identity

Peer identity is based on long-lived X25519 static public keys, pinned in persistent state after trust establishment. Certificates used for mTLS should be short-lived and mapped to the pinned peer identity by the control plane.

## Observability

OpenTelemetry spans must not include private keys, raw shared secrets, session keys, plaintext payloads, or bearer tokens. Use peer IDs, route IDs, and stable error classes instead of sensitive values.

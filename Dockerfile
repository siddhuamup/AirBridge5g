# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Copy go module definitions
COPY core/go/go.mod core/go/go.sum ./

# Copy source code
COPY core/go/ ./
COPY proto/ ./proto/

# Build statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/airbridge-node ./cmd/securemesh-node

# Runtime stage
FROM alpine:3.19

RUN apk add --no-cache ca-certificates iptables tzdata

WORKDIR /app
COPY --from=builder /bin/airbridge-node /usr/local/bin/airbridge-node

EXPOSE 1080 4433 50051

ENTRYPOINT ["/usr/local/bin/airbridge-node"]

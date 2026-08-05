package security

import (
	"crypto/tls"
	"crypto/x509"
)

const ALPN = "securemesh/1"

func ServerTLSConfig(cert tls.Certificate, clientCAs *x509.CertPool) *tls.Config {
	return &tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS13,
		ClientAuth:   tls.RequireAndVerifyClientCert,
		ClientCAs:    clientCAs,
		NextProtos:   []string{ALPN},
	}
}

func ClientTLSConfig(cert tls.Certificate, roots *x509.CertPool, serverName string) *tls.Config {
	return &tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS13,
		RootCAs:      roots,
		ServerName:   serverName,
		NextProtos:   []string{ALPN},
	}
}

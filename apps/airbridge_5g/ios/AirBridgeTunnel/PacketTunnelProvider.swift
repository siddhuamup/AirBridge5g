import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    // We would normally connect this to the Go daemon (compiled as a C-archive or framework)
    // For this mock implementation, we provide the SOCKS5 interception logic directly in Swift
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let proxyHost = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration?["proxy_host"] as? String ?? "127.0.0.1"
        let proxyPort = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration?["proxy_port"] as? Int ?? 1080
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: proxyHost)
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.255"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        networkSettings.ipv4Settings = ipv4Settings
        
        networkSettings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        
        let proxySettings = NEProxySettings()
        proxySettings.socksEnabled = true
        proxySettings.socksServer = NEProxyServer(address: proxyHost, port: proxyPort)
        proxySettings.matchDomains = [""]
        networkSettings.proxySettings = proxySettings
        
        setTunnelNetworkSettings(networkSettings) { error in
            if let error = error {
                NSLog("[AirBridge-iOS] Failed to set tunnel network settings: \(error)")
                completionHandler(error)
                return
            }
            
            // In a real app, this is where we'd start tun2socks in the Go backend
            // For now, we simulate success
            NSLog("[AirBridge-iOS] PacketTunnelProvider started, routing to \(proxyHost):\(proxyPort)")
            completionHandler(nil)
            
            self.readPackets()
        }
    }
    
    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            // Normally we'd pass these raw IP packets to tun2socks (Go or Swift equivalent).
            // Since proxySettings.socksEnabled is set, iOS automatically routes TCP traffic
            // to the SOCKS proxy we defined, so we don't strictly *need* tun2socks for basic HTTP/TCP.
            // But we keep this loop alive to discard or handle UDP/ICMP traffic if needed.
            
            self.readPackets()
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[AirBridge-iOS] PacketTunnelProvider stopped with reason: \(reason.rawValue)")
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Handle IPC from the main app
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func wake() {
        // Wake up logic
    }
}

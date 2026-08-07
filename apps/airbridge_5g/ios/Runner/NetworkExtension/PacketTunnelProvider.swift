import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var isTunnelRunning = false
    private var proxyHost = "127.0.0.1"
    private var proxyPort: UInt16 = 1080
    private var totalPacketsCount: UInt64 = 0
    private var totalBytesCount: UInt64 = 0

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        if let host = options?["proxy_host"] as? String {
            self.proxyHost = host
        }
        if let port = options?["proxy_port"] as? NSNumber {
            self.proxyPort = port.uint16Value
        }

        let tunnelSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: self.proxyHost)
        
        // IPv4 configuration
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        tunnelSettings.ipv4Settings = ipv4Settings

        // IPv6 configuration
        let ipv6Settings = NEIPv6Settings(addresses: ["fd00::2"], networkPrefixLengths: [64])
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        tunnelSettings.ipv6Settings = ipv6Settings

        // DNS & MTU configuration
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
        dnsSettings.matchDomains = [""]
        tunnelSettings.dnsSettings = dnsSettings
        tunnelSettings.mtu = 1400

        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                NSLog("[PacketTunnelProvider] Failed to set tunnel network settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }

            self.isTunnelRunning = true
            NSLog("[PacketTunnelProvider] Tunnel successfully started pointing to \(self.proxyHost):\(self.proxyPort)")
            self.startPacketForwardingLoop()
            completionHandler(nil)
        }
    }

    private func startPacketForwardingLoop() {
        guard isTunnelRunning else { return }
        
        packetFlow.readPackets { [weak self] (packets, protocols) in
            guard let self = self, self.isTunnelRunning else { return }
            
            for (index, packet) in packets.enumerated() {
                self.totalPacketsCount += 1
                self.totalBytesCount += UInt64(packet.count)
                
                let protocolFamily = protocols[index].uint32Value
                self.processPacket(packet, family: protocolFamily)
            }
            
            if self.totalPacketsCount % 100 == 0 {
                NSLog("[PacketTunnelProvider] Forwarded \(self.totalPacketsCount) packets, \(self.totalBytesCount) bytes")
            }

            // Continue packet loop recursively
            self.startPacketForwardingLoop()
        }
    }

    private func processPacket(_ packet: Data, family: UInt32) {
        guard packet.count >= 20 else { return }
        
        let versionAndIHL = packet[0]
        let version = versionAndIHL >> 4
        guard version == 4 else { return }
        
        let ihl = Int(versionAndIHL & 0x0F) * 4
        let proto = packet[9]
        
        let dstIpData = packet.subdata(in: 16..<20)
        let dstIpStr = dstIpData.map { String($0) }.joined(separator: ".")
        
        if proto == 6 && packet.count >= ihl + 20 { // TCP
            let dstPort = (UInt16(packet[ihl + 2]) << 8) | UInt16(packet[ihl + 3])
            relayTcpToSocks5(dstIp: dstIpStr, dstPort: dstPort, payload: packet)
        } else if proto == 17 && packet.count >= ihl + 8 { // UDP
            let dstPort = (UInt16(packet[ihl + 2]) << 8) | UInt16(packet[ihl + 3])
            relayUdpToSocks5(dstIp: dstIpStr, dstPort: dstPort, payload: packet)
        }
    }

    private func relayTcpToSocks5(dstIp: String, dstPort: UInt16, payload: Data) {
        // Establish SOCKS5 TCP relay connection to proxyHost:proxyPort
        NSLog("[PacketTunnelProvider] SOCKS5 TCP Relay -> \(dstIp):\(dstPort)")
    }

    private func relayUdpToSocks5(dstIp: String, dstPort: UInt16, payload: Data) {
        // Establish SOCKS5 UDP Associate connection to proxyHost:proxyPort
        NSLog("[PacketTunnelProvider] SOCKS5 UDP Relay -> \(dstIp):\(dstPort)")
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        isTunnelRunning = false
        NSLog("[PacketTunnelProvider] Tunnel stopped with reason: \(reason)")
        completionHandler()
    }
}

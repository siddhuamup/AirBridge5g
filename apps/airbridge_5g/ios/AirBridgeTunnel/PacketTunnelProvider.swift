import NetworkExtension
import Foundation
import Network

class SwiftTcpSession {
    let srcIp: UInt32
    let dstIp: UInt32
    let srcPort: UInt16
    let dstPort: UInt16
    var connection: NWConnection?
    var isConnected = false
    var serverSeq: UInt32 = UInt32.random(in: 1000...99999)
    var clientSeq: UInt32 = 0
    
    init(srcIp: UInt32, dstIp: UInt32, srcPort: UInt16, dstPort: UInt16) {
        self.srcIp = srcIp
        self.dstIp = dstIp
        self.srcPort = srcPort
        self.dstPort = dstPort
    }
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var activeSessions = [String: SwiftTcpSession]()
    private var proxyHost: String = "127.0.0.1"
    private var proxyPort: UInt16 = 1080
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        proxyHost = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration?["proxy_host"] as? String ?? "127.0.0.1"
        proxyPort = UInt16((protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration?["proxy_port"] as? Int ?? 1080)
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: proxyHost)
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.255"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        networkSettings.ipv4Settings = ipv4Settings
        
        networkSettings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        
        let proxySettings = NEProxySettings()
        proxySettings.socksEnabled = true
        proxySettings.socksServer = NEProxyServer(address: proxyHost, port: Int(proxyPort))
        proxySettings.matchDomains = [""]
        networkSettings.proxySettings = proxySettings
        
        setTunnelNetworkSettings(networkSettings) { error in
            if let error = error {
                NSLog("[AirBridge-iOS] Failed to set tunnel network settings: \(error)")
                completionHandler(error)
                return
            }
            
            NSLog("[AirBridge-iOS] PacketTunnelProvider started with Swift Tun2Socks Engine, routing to \(self.proxyHost):\(self.proxyPort)")
            completionHandler(nil)
            
            self.readPackets()
        }
    }
    
    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            for (index, packet) in packets.enumerated() {
                let family = protocols[index].uint32Value
                if family == AF_INET {
                    self.processIPv4Packet(packet)
                }
            }
            self.readPackets()
        }
    }

    private func processIPv4Packet(_ packet: Data) {
        guard packet.count >= 40 else { return } // IPv4 (20) + TCP (20)
        
        packet.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
            guard let bytes = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
            
            let versionAndIHL = bytes[0]
            let version = (versionAndIHL >> 4) & 0x0F
            let ihl = Int(versionAndIHL & 0x0F) * 4
            let protocolType = bytes[9]
            
            guard version == 4, protocolType == 6, packet.count >= ihl + 20 else { return } // Only TCP
            
            let srcIp = rawBuffer.load(fromByteOffset: 12, as: UInt32.self)
            let dstIp = rawBuffer.load(fromByteOffset: 16, as: UInt32.self)
            
            let tcpBytes = bytes + ihl
            let srcPort = (UInt16(tcpBytes[0]) << 8) | UInt16(tcpBytes[1])
            let dstPort = (UInt16(tcpBytes[2]) << 8) | UInt16(tcpBytes[3])
            let seqNum = UInt32(bigEndian: rawBuffer.load(fromByteOffset: ihl + 4, as: UInt32.self))
            let flags = UInt16(tcpBytes[13])
            
            let isSyn = (flags & 0x02) != 0
            let isFin = (flags & 0x01) != 0
            let isRst = (flags & 0x04) != 0
            
            let sessionKey = "\(srcIp):\(srcPort)-\(dstIp):\(dstPort)"
            
            if isSyn && activeSessions[sessionKey] == nil {
                let session = SwiftTcpSession(srcIp: srcIp, dstIp: dstIp, srcPort: srcPort, dstPort: dstPort)
                session.clientSeq = seqNum + 1
                activeSessions[sessionKey] = session
                self.connectSocks5Proxy(session: session)
            } else if let session = activeSessions[sessionKey] {
                if isFin || isRst {
                    session.connection?.cancel()
                    activeSessions.removeValue(forKey: sessionKey)
                } else {
                    let dataOffset = Int((tcpBytes[12] >> 4) & 0x0F) * 4
                    let payloadOffset = ihl + dataOffset
                    if packet.count > payloadOffset {
                        let payload = packet.subdata(in: payloadOffset..<packet.count)
                        session.connection?.send(content: payload, completion: .contentReceived({ _ in }))
                    }
                }
            }
        }
    }

    private func connectSocks5Proxy(session: SwiftTcpSession) {
        let host = NWEndpoint.Host(proxyHost)
        let port = NWEndpoint.Port(rawValue: proxyPort)!
        let connection = NWConnection(host: host, port: port, using: .tcp)
        session.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            if case .ready = state {
                self.performSocks5Handshake(session: session)
            } else if case .failed(_) = state, case .cancelled = state {
                session.isConnected = false
            }
        }
        connection.start(queue: .global())
    }

    private func performSocks5Handshake(session: SwiftTcpSession) {
        guard let conn = session.connection else { return }
        
        // Greeting
        let greeting = Data([0x05, 0x01, 0x00])
        conn.send(content: greeting, completion: .contentReceived({ _ in }))
        
        conn.receive(minimumIncompleteLength: 2, maximumLength: 2) { [weak self] data, _, _, _ in
            guard let self = self, let data = data, data.count == 2, data[1] == 0x00 else { return }
            
            // Connect Request
            var req = Data([0x05, 0x01, 0x00, 0x01])
            var dstIpBig = session.dstIp
            req.append(Data(bytes: &dstIpBig, count: 4))
            var dstPortBig = session.dstPort.bigEndian
            req.append(Data(bytes: &dstPortBig, count: 2))
            
            conn.send(content: req, completion: .contentReceived({ _ in }))
            
            conn.receive(minimumIncompleteLength: 10, maximumLength: 10) { data, _, _, _ in
                guard let data = data, data.count >= 2, data[1] == 0x00 else { return }
                session.isConnected = true
                self.startProxyReadLoop(session: session)
            }
        }
    }

    private func startProxyReadLoop(session: SwiftTcpSession) {
        guard let conn = session.connection, session.isConnected else { return }
        conn.receive(minimumIncompleteLength: 1, maximumLength: 32767) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else { return }
            
            // Re-synthesize TCP packet to TUN packetFlow
            self.sendTcpPacketToTun(session: session, payload: data)
            
            if !isComplete && error == nil {
                self.startProxyReadLoop(session: session)
            }
        }
    }

    private func sendTcpPacketToTun(session: SwiftTcpSession, payload: Data) {
        let totalLen = 40 + payload.count
        var packet = Data(count: totalLen)
        
        // IPv4 Header (20 bytes)
        packet[0] = 0x45
        packet[2] = UInt8((totalLen >> 8) & 0xFF)
        packet[3] = UInt8(totalLen & 0xFF)
        packet[8] = 64 // TTL
        packet[9] = 6  // TCP
        
        var src = session.dstIp
        var dst = session.srcIp
        packet.replaceSubrange(12..<16, with: Data(bytes: &src, count: 4))
        packet.replaceSubrange(16..<20, with: Data(bytes: &dst, count: 4))
        
        // TCP Header (20 bytes)
        var srcP = session.dstPort.bigEndian
        var dstP = session.srcPort.bigEndian
        packet.replaceSubrange(20..<22, with: Data(bytes: &srcP, count: 2))
        packet.replaceSubrange(22..<24, with: Data(bytes: &dstP, count: 2))
        
        var seq = session.serverSeq.bigEndian
        var ack = session.clientSeq.bigEndian
        packet.replaceSubrange(24..<28, with: Data(bytes: &seq, count: 4))
        packet.replaceSubrange(28..<32, with: Data(bytes: &ack, count: 4))
        
        packet[32] = 0x50 // Data offset 5
        packet[33] = 0x18 // PSH | ACK
        packet[34] = 0xFF // Window size
        packet[35] = 0xFF
        
        packet.replaceSubrange(40..<totalLen, with: payload)
        session.serverSeq += UInt32(payload.count)

        // Calculate IPv4 Checksum
        let ipChecksum = computeChecksum(packet, offset: 0, length: 20)
        packet[10] = UInt8((ipChecksum >> 8) & 0xFF)
        packet[11] = UInt8(ipChecksum & 0xFF)

        // Calculate TCP Checksum
        let tcpChecksum = computeTcpChecksum(packet, payloadLen: payload.count, srcIp: session.dstIp, dstIp: session.srcIp)
        packet[36] = UInt8((tcpChecksum >> 8) & 0xFF)
        packet[37] = UInt8(tcpChecksum & 0xFF)
        
        packetFlow.writePackets([packet], withProtocols: [NSNumber(value: AF_INET)])
    }

    private func computeChecksum(_ data: Data, offset: Int, length: Int) -> UInt16 {
        var sum: UInt32 = 0
        data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
            guard let bytes = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
            var i = 0
            while i < length - 1 {
                let word = (UInt32(bytes[offset + i]) << 8) | UInt32(bytes[offset + i + 1])
                sum += word
                i += 2
            }
            if i < length {
                sum += UInt32(bytes[offset + i]) << 8
            }
        }
        while (sum >> 16) > 0 {
            sum = (sum & 0xFFFF) + (sum >> 16)
        }
        return UInt16(~sum & 0xFFFF)
    }

    private func computeTcpChecksum(_ packet: Data, payloadLen: Int, srcIp: UInt32, dstIp: UInt32) -> UInt16 {
        var pseudoHeader = Data(count: 12)
        var src = srcIp
        var dst = dstIp
        pseudoHeader.replaceSubrange(0..<4, with: Data(bytes: &src, count: 4))
        pseudoHeader.replaceSubrange(4..<8, with: Data(bytes: &dst, count: 4))
        pseudoHeader[8] = 0
        pseudoHeader[9] = 6 // protocol TCP
        var tcpLenBig = UInt16(20 + payloadLen).bigEndian
        pseudoHeader.replaceSubrange(10..<12, with: Data(bytes: &tcpLenBig, count: 2))
        
        let tcpData = pseudoHeader + packet.subdata(in: 20..<(20 + 20 + payloadLen))
        return computeChecksum(tcpData, offset: 0, length: tcpData.count)
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[AirBridge-iOS] PacketTunnelProvider stopped with reason: \(reason.rawValue)")
        activeSessions.values.forEach { $0.connection?.cancel() }
        activeSessions.removeAll()
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func wake() {
    }
}

import NetworkExtension
import Flutter

/// Flutter MethodChannel handler for iOS VPN/Proxy configuration.
/// Uses NEProxySettings via NETunnelProviderManager for system-wide SOCKS5 proxy routing.
class VpnMethodChannelHandler: NSObject {
    static let channelName = "com.airbridge/ios_vpn"
    
    private var manager: NETunnelProviderManager?
    private let channel: FlutterMethodChannel
    
    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: VpnMethodChannelHandler.channelName, binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler(handle)
        loadManager()
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startVpn":
            guard let args = call.arguments as? [String: Any],
                  let host = args["proxy_host"] as? String,
                  let port = args["proxy_port"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing proxy_host or proxy_port", details: nil))
                return
            }
            startVpn(host: host, port: port, result: result)
            
        case "stopVpn":
            stopVpn(result: result)
            
        case "isVpnActive":
            isVpnActive(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func loadManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                NSLog("[AirBridge-iOS] Failed to load VPN managers: \(error)")
                return
            }
            self?.manager = managers?.first ?? NETunnelProviderManager()
        }
    }
    
    private func startVpn(host: String, port: Int, result: @escaping FlutterResult) {
        let mgr = manager ?? NETunnelProviderManager()
        self.manager = mgr
        
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "com.airbridge.airbridge5g.tunnel"
        proto.serverAddress = "\(host):\(port)"
        
        // Configure SOCKS proxy via NEProxySettings
        let proxySettings = NEProxySettings()
        proxySettings.socksEnabled = true
        proxySettings.socksServer = NEProxyServer(address: host, port: port)
        proxySettings.matchDomains = [""] // Route all domains through proxy
        proto.proxySettings = proxySettings
        
        // Provider configuration passed to the tunnel extension
        proto.providerConfiguration = [
            "proxy_host": host,
            "proxy_port": port
        ]
        
        mgr.protocolConfiguration = proto
        mgr.localizedDescription = "AirBridge 5G"
        mgr.isEnabled = true
        
        mgr.saveToPreferences { [weak self] error in
            if let error = error {
                NSLog("[AirBridge-iOS] Save VPN preferences failed: \(error)")
                result(false)
                return
            }
            
            // Reload after save (required by iOS)
            mgr.loadFromPreferences { error in
                if let error = error {
                    NSLog("[AirBridge-iOS] Reload VPN preferences failed: \(error)")
                    result(false)
                    return
                }
                
                do {
                    try mgr.connection.startVPNTunnel()
                    NSLog("[AirBridge-iOS] VPN tunnel started → \(host):\(port)")
                    result(true)
                } catch {
                    NSLog("[AirBridge-iOS] Start VPN tunnel failed: \(error)")
                    result(false)
                }
            }
        }
    }
    
    private func stopVpn(result: @escaping FlutterResult) {
        guard let mgr = manager else {
            result(true)
            return
        }
        mgr.connection.stopVPNTunnel()
        NSLog("[AirBridge-iOS] VPN tunnel stopped")
        result(true)
    }
    
    private func isVpnActive(result: @escaping FlutterResult) {
        guard let mgr = manager else {
            result(false)
            return
        }
        let status = mgr.connection.status
        result(status == .connected || status == .connecting)
    }
}

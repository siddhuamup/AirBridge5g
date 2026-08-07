import UIKit
import Flutter
import NetworkExtension

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // Register both channels for backward and platform compatibility
    let setupVpnChannel = { (channelName: String) in
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "startVpn":
          let args = call.arguments as? [String: Any]
          let proxyHost = args?["proxy_host"] as? String ?? "127.0.0.1"
          let proxyPort = args?["proxy_port"] as? Int ?? 1080
          
          NETunnelProviderManager.loadAllFromPreferences { managers, error in
            let manager = managers?.first ?? NETunnelProviderManager()
            let protocolConfiguration = NETunnelProviderProtocol()
            protocolConfiguration.providerBundleIdentifier = "com.airbridge.airbridge5g.PacketTunnelProvider"
            protocolConfiguration.serverAddress = "\(proxyHost):\(proxyPort)"
            protocolConfiguration.providerConfiguration = [
              "proxy_host": proxyHost,
              "proxy_port": proxyPort
            ]
            
            manager.protocolConfiguration = protocolConfiguration
            manager.localizedDescription = "AirBridge 5G Network Resilience"
            manager.isEnabled = true
            
            manager.saveToPreferences { error in
              if let error = error {
                result(FlutterError(code: "VPN_SAVE_ERROR", message: error.localizedDescription, details: nil))
                return
              }
              manager.loadFromPreferences { _ in
                do {
                  try manager.connection.startVPNTunnel()
                  result(true)
                } catch {
                  result(FlutterError(code: "VPN_START_ERROR", message: error.localizedDescription, details: nil))
                }
              }
            }
          }
        case "stopVpn":
          NETunnelProviderManager.loadAllFromPreferences { managers, _ in
            if let manager = managers?.first {
              manager.connection.stopVPNTunnel()
            }
            result(true)
          }
        case "isVpnActive":
          NETunnelProviderManager.loadAllFromPreferences { managers, _ in
            let isActive = managers?.first?.connection.status == .connected
            result(isActive)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      })
    }

    setupVpnChannel("com.airbridge/vpn")
    setupVpnChannel("com.airbridge/ios_vpn")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

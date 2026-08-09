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
          if self.isJailbroken() {
            result(FlutterError(code: "SECURITY_VIOLATION", message: "Jailbroken iOS device detected. VPN operation disabled for security.", details: nil))
            return
          }
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

  private func isJailbroken() -> Bool {
    let paths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/",
      "/usr/libexec/ssh-keysign"
    ]
    for path in paths {
      if FileManager.default.fileExists(atPath: path) {
        return true
      }
    }

    // Test sandbox escape write permission
    let testStr = "JailbreakTest"
    do {
      try testStr.write(toFile: "/private/jailbreak_test.txt", atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: "/private/jailbreak_test.txt")
      return true
    } catch {
      // Expected sandboxed error
    }

    // Test cydia URL scheme
    if let url = URL(string: "cydia://package/com.example.package"), UIApplication.shared.canOpenURL(url) {
      return true
    }

    return false
  }
}

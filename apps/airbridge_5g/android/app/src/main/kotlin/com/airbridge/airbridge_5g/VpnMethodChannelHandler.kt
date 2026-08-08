package com.airbridge.airbridge_5g

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter MethodChannel handler for the AirBridge VPN service.
 * Bridges Dart calls to the native Android VpnService.
 */
class VpnMethodChannelHandler(
    private val activity: Activity,
    flutterEngine: FlutterEngine
) {
    companion object {
        const val CHANNEL = "com.airbridge/vpn"
        const val VPN_REQUEST_CODE = 24601
    }

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    private var pendingProxyHost: String? = null
    private var pendingProxyPort: Int = 1080

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val host = call.argument<String>("proxy_host") ?: "127.0.0.1"
                    val port = call.argument<Int>("proxy_port") ?: 1080
                    startVpn(host, port, result)
                }
                "stopVpn" -> {
                    stopVpn(result)
                }
                "isVpnActive" -> {
                    result.success(AirBridgeVpnService.isRunning)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVpn(host: String, port: Int, result: MethodChannel.Result) {
        val intent = VpnService.prepare(activity)
        if (intent != null) {
            // Need user permission — store pending config
            pendingProxyHost = host
            pendingProxyPort = port
            activity.startActivityForResult(intent, VPN_REQUEST_CODE)
            result.success(true) // Permission dialog shown
        } else {
            // Already authorized — start immediately
            launchVpnService(host, port)
            result.success(true)
        }
    }

    private fun stopVpn(result: MethodChannel.Result) {
        val intent = Intent(activity, AirBridgeVpnService::class.java).apply {
            action = AirBridgeVpnService.ACTION_DISCONNECT
        }
        activity.startService(intent)
        result.success(true)
    }

    fun launchVpnService(host: String, port: Int) {
        val intent = Intent(activity, AirBridgeVpnService::class.java).apply {
            action = AirBridgeVpnService.ACTION_CONNECT
            putExtra(AirBridgeVpnService.EXTRA_PROXY_HOST, host)
            putExtra(AirBridgeVpnService.EXTRA_PROXY_PORT, port)
        }
        activity.startService(intent)
    }

    /**
     * Called from Activity.onActivityResult when VPN permission is granted.
     */
    fun onActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            val host = pendingProxyHost ?: "127.0.0.1"
            val port = pendingProxyPort
            launchVpnService(host, port)
        }
        pendingProxyHost = null
    }
}

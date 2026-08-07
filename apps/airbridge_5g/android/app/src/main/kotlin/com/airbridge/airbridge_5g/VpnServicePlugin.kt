package com.airbridge.airbridge_5g

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VpnServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.airbridge/vpn")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVpn" -> {
                val proxyHost = call.argument<String>("proxy_host") ?: "127.0.0.1"
                val proxyPort = call.argument<Int>("proxy_port") ?: 1080
                
                val vpnIntent = Intent(context, AirBridgeVpnService::class.java).apply {
                    action = "ACTION_CONNECT"
                    putExtra("proxy_host", proxyHost)
                    putExtra("proxy_port", proxyPort)
                }
                ContextCompat.startForegroundService(context, vpnIntent)
                result.success(true)
            }
            "stopVpn" -> {
                val stopIntent = Intent(context, AirBridgeVpnService::class.java).apply {
                    action = "ACTION_DISCONNECT"
                }
                context.startService(stopIntent)
                result.success(true)
            }
            "isVpnActive" -> {
                result.success(AirBridgeVpnService.isRunning)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

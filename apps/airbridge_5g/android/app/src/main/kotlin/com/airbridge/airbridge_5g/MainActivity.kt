package com.airbridge.airbridge_5g

import android.content.Intent
import android.net.VpnService
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.airbridge/vpn"
    private val VPN_REQUEST_CODE = 0xAF

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        onActivityResult(VPN_REQUEST_CODE, RESULT_OK, null)
                    }
                    val proxyHost = call.argument<String>("proxyHost") ?: "127.0.0.1"
                    val proxyPort = call.argument<Int>("proxyPort") ?: 1080
                    
                    val vpnIntent = Intent(this, AirBridgeVpnService::class.java).apply {
                        putExtra("proxyHost", proxyHost)
                        putExtra("proxyPort", proxyPort)
                    }
                    startService(vpnIntent)
                    result.success(true)
                }
                "stopVpn" -> {
                    val stopIntent = Intent(this, AirBridgeVpnService::class.java).apply {
                        action = "STOP"
                    }
                    startService(stopIntent)
                    result.success(true)
                }
                "isVpnActive" -> {
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

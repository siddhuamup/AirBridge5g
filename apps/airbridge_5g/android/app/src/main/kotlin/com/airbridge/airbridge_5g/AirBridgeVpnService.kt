package com.airbridge.airbridge_5g

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

class AirBridgeVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        val proxyHost = intent?.getStringExtra("proxyHost") ?: "127.0.0.1"
        val proxyPort = intent?.getIntExtra("proxyPort", 1080) ?: 1080

        startVpn(proxyHost, proxyPort)
        return START_STICKY
    }

    private fun startVpn(proxyHost: String, proxyPort: Int) {
        try {
            val builder = Builder()
                .setSession("AirBridge 5G Tunnel")
                .addAddress("10.0.0.2", 24)
                .addRoute("0.0.0.0", 0)
                .setMtu(1500)
                .setHttpProxy(android.net.ProxyInfo.buildDirectProxy(proxyHost, proxyPort))

            vpnInterface = builder.establish()
            Log.i("AirBridgeVpnService", "VPN tunnel established pointing to SOCKS5 proxy $proxyHost:$proxyPort")
        } catch (e: Exception) {
            Log.e("AirBridgeVpnService", "Failed to establish VPN tunnel: ${e.message}", e)
        }
    }

    private fun stopVpn() {
        try {
            vpnInterface?.close()
            vpnInterface = null
            stopSelf()
            Log.i("AirBridgeVpnService", "VPN tunnel stopped")
        } catch (e: Exception) {
            Log.e("AirBridgeVpnService", "Error stopping VPN: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}

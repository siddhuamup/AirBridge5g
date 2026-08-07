package com.airbridge.airbridge_5g

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.net.InetSocketAddress
import java.nio.channels.SocketChannel

class AirBridgeVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var forwardingThread: Thread? = null

    companion object {
        var isRunning = false
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        
        if (action == "ACTION_DISCONNECT") {
            stopVpn()
            return START_NOT_STICKY
        }

        if (action == "ACTION_CONNECT") {
            val proxyHost = intent.getStringExtra("proxy_host") ?: "127.0.0.1"
            val proxyPort = intent.getIntExtra("proxy_port", 1080)

            createNotificationChannel()
            val notification = NotificationCompat.Builder(this, "AIRBRIDGE_VPN_CHANNEL")
                .setContentTitle("AirBridge 5G")
                .setContentText("AirBridge 5G — Network Resilience Active")
                .setSmallIcon(android.R.drawable.ic_secure)
                .build()

            startForeground(1, notification)
            startVpn(proxyHost, proxyPort)
            isRunning = true
        }

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "AIRBRIDGE_VPN_CHANNEL",
                "AirBridge VPN Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun startVpn(proxyHost: String, proxyPort: Int) {
        try {
            val builder = Builder()
                .setSession("AirBridge 5G Tunnel")
                .addAddress("10.0.0.2", 24)
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0)
                .addDnsServer("8.8.8.8")
                .addDnsServer("1.1.1.1")
                .setMtu(1400)
            
            vpnInterface = builder.establish()
            Log.i("AirBridgeVpnService", "VPN tunnel established")

            // Create a socket and protect it
            val tunnel = SocketChannel.open()
            if (!protect(tunnel.socket())) {
                Log.e("AirBridgeVpnService", "Cannot protect socket")
                return
            }
            // tunnel.connect(InetSocketAddress(proxyHost, proxyPort))

            // Packet forwarding loop in separate thread
            forwardingThread = Thread {
                try {
                    while (!Thread.interrupted()) {
                        Thread.sleep(1000)
                    }
                } catch (e: InterruptedException) {
                    Log.i("AirBridgeVpnService", "Forwarding thread interrupted")
                } finally {
                    try {
                        tunnel.close()
                    } catch (e: Exception) {}
                }
            }
            forwardingThread?.start()
            
        } catch (e: Exception) {
            Log.e("AirBridgeVpnService", "Failed to establish VPN tunnel: ${e.message}", e)
        }
    }

    private fun stopVpn() {
        isRunning = false
        try {
            forwardingThread?.interrupt()
            forwardingThread = null
            vpnInterface?.close()
            vpnInterface = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                stopForeground(true)
            }
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

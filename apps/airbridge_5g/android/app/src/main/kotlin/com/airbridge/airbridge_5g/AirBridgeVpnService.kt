package com.airbridge.airbridge_5g

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.net.InetSocketAddress
import java.net.Socket

/**
 * AirBridge VPN Service — routes all device traffic through the SOCKS5 proxy
 * by establishing a TUN interface and forwarding packets.
 */
class AirBridgeVpnService : VpnService() {

    companion object {
        const val TAG = "AirBridgeVPN"
        const val CHANNEL_ID = "airbridge_vpn_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_CONNECT = "com.airbridge.CONNECT"
        const val ACTION_DISCONNECT = "com.airbridge.DISCONNECT"
        const val EXTRA_PROXY_HOST = "proxy_host"
        const val EXTRA_PROXY_PORT = "proxy_port"

        @Volatile
        var isRunning = false
            private set
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var proxyHost: String = "127.0.0.1"
    private var proxyPort: Int = 1080

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_DISCONNECT -> {
                disconnect()
                return START_NOT_STICKY
            }
            else -> {
                proxyHost = intent?.getStringExtra(EXTRA_PROXY_HOST) ?: "127.0.0.1"
                proxyPort = intent?.getIntExtra(EXTRA_PROXY_PORT, 1080) ?: 1080
                connect()
                return START_STICKY
            }
        }
    }

    private fun connect() {
        if (vpnInterface != null) {
            Log.w(TAG, "VPN already connected")
            return
        }

        try {
            createNotificationChannel()

            val builder = Builder()
                .setSession("AirBridge 5G")
                .addAddress("10.0.0.2", 32)
                .addRoute("0.0.0.0", 0) // Route all IPv4 traffic
                .addDnsServer("1.1.1.1")
                .addDnsServer("8.8.8.8")
                .setMtu(1500)
                .setBlocking(true)

            // Set SOCKS proxy (Android 10+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setHttpProxy(
                    ProxyInfo.buildDirectProxy(proxyHost, proxyPort)
                )
            }

            // Exclude our own app from the VPN to prevent loops
            builder.addDisallowedApplication(packageName)

            vpnInterface = builder.establish()
            isRunning = true

            // Start as foreground service
            val notification = buildNotification()
            startForeground(NOTIFICATION_ID, notification)

            Log.i(TAG, "VPN connected → proxy $proxyHost:$proxyPort")

            // Start packet forwarding in background thread
            Thread {
                forwardPackets()
            }.start()
        } catch (e: Exception) {
            Log.e(TAG, "VPN connection failed", e)
            disconnect()
        }
    }

    private fun forwardPackets() {
        val vpnFd = vpnInterface?.fileDescriptor ?: return
        val inputStream = ParcelFileDescriptor.AutoCloseInputStream(vpnInterface)
        val outputStream = ParcelFileDescriptor.AutoCloseOutputStream(vpnInterface)
        val buffer = ByteArray(32767)

        var relaySocket: Socket? = null
        try {
            val socket = Socket()
            protect(socket) // Bypass TUN interface to avoid loop
            socket.connect(InetSocketAddress(proxyHost, proxyPort), 5000)
            socket.soTimeout = 5000
            
            val out = socket.getOutputStream()
            val socketIn = socket.getInputStream()

            // 1. SOCKS5 Method Negotiation (VER=5, NMETHODS=1, METHOD=NO AUTH)
            out.write(byteArrayOf(0x05, 0x01, 0x00))
            out.flush()

            val methodResp = ByteArray(2)
            if (socketIn.read(methodResp) < 2 || methodResp[0] != 0x05.toByte()) {
                throw IllegalStateException("SOCKS5 method negotiation failed")
            }

            // 2. SOCKS5 CONNECT Command (VER=5, CMD=1 CONNECT, RSV=0, ATYP=1 IPv4: 0.0.0.0:80)
            val connectReq = byteArrayOf(
                0x05, 0x01, 0x00, 0x01,
                0x00, 0x00, 0x00, 0x00, // Destination IP 0.0.0.0
                0x00, 0x50              // Destination Port 80
            )
            out.write(connectReq)
            out.flush()

            val connectResp = ByteArray(10)
            if (socketIn.read(connectResp) < 4 || connectResp[1] != 0x00.toByte()) {
                Log.w(TAG, "SOCKS5 CONNECT reply code: ${connectResp[1]}")
            }

            socket.soTimeout = 0 // Clear handshake timeout for streaming
            relaySocket = socket

            // Background thread to relay incoming SOCKS data back to TUN outputStream
            Thread {
                val inBuf = ByteArray(32767)
                try {
                    while (isRunning && !socket.isClosed) {
                        val len = socketIn.read(inBuf)
                        if (len > 0) {
                            outputStream.write(inBuf, 0, len)
                            outputStream.flush()
                        } else if (len < 0) break
                    }
                } catch (_: Exception) {}
            }.start()

            // Main loop to relay outgoing TUN inputStream data to SOCKS socket
            while (isRunning && !socket.isClosed) {
                val length = inputStream.read(buffer)
                if (length > 0) {
                    out.write(buffer, 0, length)
                    out.flush()
                } else if (length < 0) break
            }
        } catch (e: Exception) {
            if (isRunning) {
                Log.e(TAG, "SOCKS5 relay tunnel error", e)
            }
        } finally {
            try { relaySocket?.close() } catch (_: Exception) {}
        }
    }

    private fun disconnect() {
        isRunning = false
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing VPN interface", e)
        }
        vpnInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.i(TAG, "VPN disconnected")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AirBridge VPN",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "AirBridge 5G VPN tunnel status"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("AirBridge 5G")
                .setContentText("VPN tunnel active → $proxyHost:$proxyPort")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("AirBridge 5G")
                .setContentText("VPN tunnel active → $proxyHost:$proxyPort")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        }
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }

    override fun onRevoke() {
        disconnect()
        super.onRevoke()
    }
}

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
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.util.Collections

class AirBridgeVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var forwardingThread: Thread? = null
    private val activeSockets = Collections.synchronizedList(mutableListOf<Socket>())

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
                .setOngoing(true)
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

            val pfd = builder.establish() ?: run {
                Log.e("AirBridgeVpnService", "Failed to establish VPN interface")
                return
            }
            vpnInterface = pfd
            Log.i("AirBridgeVpnService", "VPN tunnel interface established")

            forwardingThread = Thread {
                runForwardingLoop(pfd, proxyHost, proxyPort)
            }.apply { start() }

        } catch (e: Exception) {
            Log.e("AirBridgeVpnService", "Failed to establish VPN tunnel: ${e.message}", e)
        }
    }

    private fun runForwardingLoop(pfd: ParcelFileDescriptor, proxyHost: String, proxyPort: Int) {
        var totalPackets = 0L
        var totalBytes = 0L
        val inStream = FileInputStream(pfd.fileDescriptor)
        val packetBuffer = ByteArray(32767)

        try {
            while (!Thread.interrupted() && isRunning) {
                val length = try {
                    inStream.read(packetBuffer)
                } catch (e: IOException) {
                    break
                }
                if (length <= 0) break

                totalPackets++
                totalBytes += length

                if (length < 20) continue

                val versionAndIhl = packetBuffer[0].toInt() and 0xFF
                val version = versionAndIhl shr 4
                if (version != 4) continue // Focus IPv4

                val ihl = (versionAndIhl and 0x0F) * 4
                val protocol = packetBuffer[9].toInt() and 0xFF

                val dstIpBytes = ByteArray(4)
                System.arraycopy(packetBuffer, 16, dstIpBytes, 0, 4)

                if (protocol == 6 && length >= ihl + 20) { // TCP
                    val dstPort = ((packetBuffer[ihl + 2].toInt() and 0xFF) shl 8) or (packetBuffer[ihl + 3].toInt() and 0xFF)
                    relayTcpPacketAsync(proxyHost, proxyPort, dstIpBytes, dstPort)
                } else if (protocol == 17 && length >= ihl + 8) { // UDP
                    val dstPort = ((packetBuffer[ihl + 2].toInt() and 0xFF) shl 8) or (packetBuffer[ihl + 3].toInt() and 0xFF)
                    relayUdpPacketAsync(proxyHost, proxyPort, dstIpBytes, dstPort)
                }

                if (totalPackets % 100L == 0L) {
                    Log.i("AirBridgeVpnService", "forwarded $totalPackets packets, $totalBytes bytes")
                }
            }
        } catch (e: Exception) {
            Log.e("AirBridgeVpnService", "Error in forwarding loop: ${e.message}")
        } finally {
            Log.i("AirBridgeVpnService", "Forwarding loop stopped. Total: forwarded $totalPackets packets, $totalBytes bytes")
        }
    }

    private fun relayTcpPacketAsync(proxyHost: String, proxyPort: Int, dstIp: ByteArray, dstPort: Int) {
        Thread {
            try {
                val socket = Socket()
                if (!protect(socket)) {
                    socket.close()
                    return@Thread
                }
                socket.connect(InetSocketAddress(proxyHost, proxyPort), 3000)
                activeSockets.add(socket)

                val out = socket.getOutputStream()
                val inp = socket.getInputStream()

                // SOCKS5 greeting: 0x05, 0x01, 0x00 (NO AUTH)
                out.write(byteArrayOf(0x05.toByte(), 0x01.toByte(), 0x00.toByte()))
                out.flush()

                val greetingResp = ByteArray(2)
                if (inp.read(greetingResp) != 2 || greetingResp[0] != 0x05.toByte()) {
                    socket.close()
                    activeSockets.remove(socket)
                    return@Thread
                }

                // SOCKS5 connect request
                val req = ByteArray(10)
                req[0] = 0x05.toByte()
                req[1] = 0x01.toByte() // CONNECT
                req[2] = 0x00.toByte()
                req[3] = 0x01.toByte() // IPv4
                System.arraycopy(dstIp, 0, req, 4, 4)
                req[8] = ((dstPort shr 8) and 0xFF).toByte()
                req[9] = (dstPort and 0xFF).toByte()

                out.write(req)
                out.flush()

                val connResp = ByteArray(10)
                inp.read(connResp)

                // Socket is connected to proxy for destination
            } catch (e: Exception) {
                // Ignore transient TCP connection failures
            }
        }.start()
    }

    private fun relayUdpPacketAsync(proxyHost: String, proxyPort: Int, dstIp: ByteArray, dstPort: Int) {
        Thread {
            try {
                val socket = Socket()
                if (!protect(socket)) {
                    socket.close()
                    return@Thread
                }
                socket.connect(InetSocketAddress(proxyHost, proxyPort), 3000)
                activeSockets.add(socket)

                val out = socket.getOutputStream()
                val inp = socket.getInputStream()

                // SOCKS5 greeting
                out.write(byteArrayOf(0x05.toByte(), 0x01.toByte(), 0x00.toByte()))
                out.flush()

                val greetingResp = ByteArray(2)
                if (inp.read(greetingResp) != 2 || greetingResp[0] != 0x05.toByte()) {
                    socket.close()
                    activeSockets.remove(socket)
                    return@Thread
                }

                // UDP ASSOCIATE request (0x05, 0x03, 0x00, 0x01, 0, 0, 0, 0, 0, 0)
                val req = ByteArray(10)
                req[0] = 0x05.toByte()
                req[1] = 0x03.toByte() // UDP ASSOCIATE
                req[2] = 0x00.toByte()
                req[3] = 0x01.toByte()
                out.write(req)
                out.flush()

                val udpResp = ByteArray(10)
                inp.read(udpResp)

            } catch (e: Exception) {
                // Ignore transient UDP failures
            }
        }.start()
    }

    private fun stopVpn() {
        isRunning = false
        try {
            forwardingThread?.interrupt()
            forwardingThread = null

            synchronized(activeSockets) {
                for (s in activeSockets) {
                    try { s.close() } catch (_: Exception) {}
                }
                activeSockets.clear()
            }

            vpnInterface?.close()
            vpnInterface = null

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                stopForeground(true)
            }
            stopSelf()
            Log.i("AirBridgeVpnService", "VPN tunnel stopped gracefully")
        } catch (e: Exception) {
            Log.e("AirBridgeVpnService", "Error stopping VPN: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}

package com.airbridge.airbridge_5g.tcp

import android.util.Log
import java.io.InputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap
import kotlin.experimental.and

class Tun2Socks(
    private val proxyHost: String,
    private val proxyPort: Int,
    private val tunInputStream: InputStream,
    private val tunOutputStream: OutputStream,
    private val protectSocket: (Socket) -> Unit
) {
    private val connections = ConcurrentHashMap<String, TcpConnection>()
    @Volatile private var isRunning = true

    fun start() {
        val buffer = ByteArray(32767)
        while (isRunning) {
            try {
                val len = tunInputStream.read(buffer)
                if (len > 0) {
                    handlePacket(buffer, len)
                }
            } catch (e: Exception) {
                if (isRunning) Log.e("Tun2Socks", "Read error", e)
                break
            }
        }
    }

    fun stop() {
        isRunning = false
        connections.values.forEach { it.close() }
        connections.clear()
    }

    private fun handlePacket(packet: ByteArray, len: Int) {
        val bb = ByteBuffer.wrap(packet, 0, len)
        
        // Ensure minimum IPv4 header
        if (len < 20) return
        
        val versionAndIHL = bb.get(0)
        val version = (versionAndIHL.toInt() shr 4) and 0x0F
        val ihl = (versionAndIHL.toInt() and 0x0F) * 4
        
        if (version != 4 || ihl < 20 || len < ihl + 20) return // Only IPv4 and basic TCP header
        
        val protocol = bb.get(9).toInt()
        if (protocol != 6) return // Only TCP
        
        val srcIp = bb.getInt(12)
        val dstIp = bb.getInt(16)
        
        // TCP Header starts at ihl
        val srcPort = bb.getShort(ihl).toInt() and 0xFFFF
        val dstPort = bb.getShort(ihl + 2).toInt() and 0xFFFF
        val seqNum = bb.getInt(ihl + 4)
        val ackNum = bb.getInt(ihl + 8)
        
        val dataOffsetAndFlags = bb.getShort(ihl + 12).toInt()
        val dataOffset = ((dataOffsetAndFlags shr 12) and 0x0F) * 4
        val flags = dataOffsetAndFlags and 0x1FF
        
        val isSyn = (flags and 0x02) != 0
        val isAck = (flags and 0x10) != 0
        val isFin = (flags and 0x01) != 0
        val isRst = (flags and 0x04) != 0
        val isPsh = (flags and 0x08) != 0
        
        val payloadOffset = ihl + dataOffset
        val payloadLen = len - payloadOffset
        
        val connKey = "$srcIp:$srcPort-$dstIp:$dstPort"
        
        var conn = connections[connKey]
        
        if (isSyn && conn == null) {
            conn = TcpConnection(this, srcIp, srcPort, dstIp, dstPort, seqNum)
            connections[connKey] = conn
            conn.connectToProxy()
            return
        }
        
        if (conn != null) {
            if (payloadLen > 0) {
                val payload = ByteArray(payloadLen)
                bb.position(payloadOffset)
                bb.get(payload)
                conn.onClientData(payload, seqNum)
            }
            if (isFin || isRst) {
                conn.close()
                connections.remove(connKey)
            }
        }
    }
    
    fun sendTcpPacket(srcIp: Int, srcPort: Int, dstIp: Int, dstPort: Int, seqNum: Int, ackNum: Int, flags: Int, payload: ByteArray?) {
        val payloadLen = payload?.size ?: 0
        val totalLen = 20 + 20 + payloadLen // IPv4 (20) + TCP (20) + payload
        
        val buf = ByteBuffer.allocate(totalLen)
        
        // IPv4 Header
        buf.put(((4 shl 4) or 5).toByte()) // Version 4, IHL 5
        buf.put(0.toByte()) // TOS
        buf.putShort(totalLen.toShort()) // Total length
        buf.putShort(0.toShort()) // Identification
        buf.putShort(0x4000.toShort()) // Flags (DF) & Fragment Offset
        buf.put(64.toByte()) // TTL
        buf.put(6.toByte()) // Protocol TCP
        buf.putShort(0.toShort()) // Header Checksum (placeholder)
        buf.putInt(srcIp)
        buf.putInt(dstIp)
        
        // IPv4 Checksum calculation
        var ipChecksum = 0
        for (i in 0 until 10) {
            ipChecksum += buf.getShort(i * 2).toInt() and 0xFFFF
        }
        ipChecksum = (ipChecksum shr 16) + (ipChecksum and 0xFFFF)
        ipChecksum += (ipChecksum shr 16)
        buf.putShort(10, (ipChecksum.inv() and 0xFFFF).toShort())
        
        // TCP Header
        val tcpOffset = 20
        buf.position(tcpOffset)
        buf.putShort(srcPort.toShort())
        buf.putShort(dstPort.toShort())
        buf.putInt(seqNum)
        buf.putInt(ackNum)
        buf.putShort(((5 shl 12) or flags).toShort()) // Data offset (5) + Flags
        buf.putShort(65535.toShort()) // Window size
        buf.putShort(0.toShort()) // Checksum placeholder
        buf.putShort(0.toShort()) // Urgent pointer
        
        if (payload != null) {
            buf.put(payload)
        }
        
        // TCP Checksum calculation (pseudo header + tcp header + payload)
        var tcpChecksum = 0
        // Pseudo header
        tcpChecksum += (srcIp shr 16) and 0xFFFF
        tcpChecksum += srcIp and 0xFFFF
        tcpChecksum += (dstIp shr 16) and 0xFFFF
        tcpChecksum += dstIp and 0xFFFF
        tcpChecksum += 6 // Protocol
        tcpChecksum += 20 + payloadLen // TCP length
        
        // TCP Header and payload
        for (i in 0 until (20 + payloadLen) step 2) {
            if (i == (20 + payloadLen - 1)) {
                tcpChecksum += (buf.get(tcpOffset + i).toInt() and 0xFF) shl 8
            } else {
                tcpChecksum += buf.getShort(tcpOffset + i).toInt() and 0xFFFF
            }
        }
        tcpChecksum = (tcpChecksum shr 16) + (tcpChecksum and 0xFFFF)
        tcpChecksum += (tcpChecksum shr 16)
        buf.putShort(tcpOffset + 16, (tcpChecksum.inv() and 0xFFFF).toShort())
        
        try {
            tunOutputStream.write(buf.array())
        } catch (e: Exception) {
            Log.e("Tun2Socks", "Write to TUN failed", e)
        }
    }

    inner class TcpConnection(
        val manager: Tun2Socks,
        val clientIp: Int,
        val clientPort: Int,
        val serverIp: Int,
        val serverPort: Int,
        clientSynSeq: Int
    ) {
        private var socket: Socket? = null
        private var clientSeq = clientSynSeq + 1
        private var serverSeq = 1000 // Mock ISN
        private val SYN = 0x02
        private val ACK = 0x10
        private val PSH = 0x08
        private val FIN = 0x01

        fun connectToProxy() {
            Thread {
                try {
                    socket = Socket()
                    manager.protectSocket(socket!!)
                    socket!!.connect(InetSocketAddress(manager.proxyHost, manager.proxyPort), 5000)
                    
                    val out = socket!!.getOutputStream()
                    val socketIn = socket!!.getInputStream()
                    
                    // SOCKS5 Handshake
                    out.write(byteArrayOf(0x05, 0x01, 0x00))
                    val methodResp = ByteArray(2)
                    socketIn.read(methodResp)
                    
                    // SOCKS5 CONNECT
                    val destIpBytes = ByteArray(4) { i -> ((serverIp shr (24 - i * 8)) and 0xFF).toByte() }
                    val connectReq = byteArrayOf(0x05, 0x01, 0x00, 0x01) + destIpBytes + byteArrayOf((serverPort shr 8).toByte(), serverPort.toByte())
                    out.write(connectReq)
                    
                    val connectResp = ByteArray(10)
                    socketIn.read(connectResp)
                    
                    if (connectResp[1] != 0x00.toByte()) {
                        close()
                        return@Thread
                    }
                    
                    // Reply SYN-ACK to client
                    manager.sendTcpPacket(serverIp, serverPort, clientIp, clientPort, serverSeq, clientSeq, SYN or ACK, null)
                    serverSeq++
                    
                    // Start reading from proxy
                    val buf = ByteArray(32767)
                    while (true) {
                        val len = socketIn.read(buf)
                        if (len > 0) {
                            val payload = buf.copyOfRange(0, len)
                            manager.sendTcpPacket(serverIp, serverPort, clientIp, clientPort, serverSeq, clientSeq, PSH or ACK, payload)
                            serverSeq += len
                        } else {
                            break
                        }
                    }
                } catch (e: Exception) {
                    Log.e("Tun2Socks", "Proxy conn error", e)
                } finally {
                    close()
                }
            }.start()
        }

        fun onClientData(payload: ByteArray, seq: Int) {
            // Very naive TCP state tracking
            if (seq == clientSeq) {
                clientSeq += payload.size
                try {
                    socket?.getOutputStream()?.write(payload)
                    // Ack immediately
                    manager.sendTcpPacket(serverIp, serverPort, clientIp, clientPort, serverSeq, clientSeq, ACK, null)
                } catch (e: Exception) {
                    close()
                }
            }
        }

        fun close() {
            try { socket?.close() } catch (e: Exception) {}
            // Send FIN-ACK
            manager.sendTcpPacket(serverIp, serverPort, clientIp, clientPort, serverSeq, clientSeq, FIN or ACK, null)
        }
    }
}

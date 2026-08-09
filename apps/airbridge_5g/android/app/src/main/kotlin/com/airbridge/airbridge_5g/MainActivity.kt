package com.airbridge.airbridge_5g

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {

    private val OTA_CHANNEL = "com.airbridge/ota"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(VpnServicePlugin())
        
        val SECURITY_CHANNEL = "com.airbridge/security"
        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setFlagSecure" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    if (enable) {
                        window.setFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE, android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                "checkAntiTamper" -> {
                    result.success(!isTamperedOrEmulator())
                }
                "requestBatteryOptimizationExemption" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = android.net.Uri.parse("package:" + packageName)
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OTA_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "downloadApk") {
                val url = call.argument<String>("url")
                if (url != null) {
                    downloadApk(url)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "URL is missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isTamperedOrEmulator(): Boolean {
        val details = android.os.Build.FINGERPRINT + android.os.Build.MODEL + android.os.Build.MANUFACTURER + android.os.Build.HARDWARE
        return details.contains("generic") ||
               details.contains("emulator") ||
               details.contains("sdk_gphone") ||
               details.contains("vbox86p")
    }

    private fun downloadApk(url: String) {
        val request = android.app.DownloadManager.Request(android.net.Uri.parse(url))
        request.setDestinationInExternalPublicDir(android.os.Environment.DIRECTORY_DOWNLOADS, "airbridge_update.apk")
        request.setNotificationVisibility(android.app.DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
        request.setTitle("AirBridge 5G Update")
        val manager = getSystemService(android.content.Context.DOWNLOAD_SERVICE) as android.app.DownloadManager
        manager.enqueue(request)
    }
}

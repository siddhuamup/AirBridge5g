package com.airbridge.airbridge_5g

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {

    private val OTA_CHANNEL = "com.airbridge/ota"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(VpnServicePlugin())
        
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

    private fun downloadApk(url: String) {
        val request = android.app.DownloadManager.Request(android.net.Uri.parse(url))
        request.setDestinationInExternalPublicDir(android.os.Environment.DIRECTORY_DOWNLOADS, "airbridge_update.apk")
        request.setNotificationVisibility(android.app.DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
        request.setTitle("AirBridge 5G Update")
        val manager = getSystemService(android.content.Context.DOWNLOAD_SERVICE) as android.app.DownloadManager
        manager.enqueue(request)
    }
}

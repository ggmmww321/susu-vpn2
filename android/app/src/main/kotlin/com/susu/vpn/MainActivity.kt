package com.susu.vpn

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.susu.vpn.vpn.VpnManager

class MainActivity : FlutterActivity() {

    private val VPN_CHANNEL = "com.susu.vpn/vpn_service"
    private val STATS_CHANNEL = "com.susu.vpn/vpn_stats"
    private lateinit var vpnManager: VpnManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        vpnManager = VpnManager(this)

        // VPN控制通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startVpn" -> {
                        val config = call.argument<String>("config") ?: ""
                        val nodeName = call.argument<String>("nodeName") ?: ""
                        vpnManager.startVpn(config, nodeName, result)
                    }
                    "stopVpn" -> {
                        vpnManager.stopVpn(result)
                    }
                    "getStats" -> {
                        val stats = vpnManager.getStats()
                        result.success(stats)
                    }
                    else -> result.notImplemented()
                }
            }

        // 状态回调（Flutter -> Native 注册监听）
        vpnManager.setFlutterChannel(
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        vpnManager.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        vpnManager.release()
        super.onDestroy()
    }
}

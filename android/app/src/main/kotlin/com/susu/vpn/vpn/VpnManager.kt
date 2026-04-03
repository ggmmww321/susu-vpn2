package com.susu.vpn.vpn

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.net.VpnService
import android.os.IBinder
import io.flutter.plugin.common.MethodChannel

/**
 * VPN管理器 - 负责协调 VpnService 启动/停止和 Flutter 通信
 */
class VpnManager(private val activity: Activity) {

    companion object {
        const val VPN_REQUEST_CODE = 100
    }

    private var flutterChannel: MethodChannel? = null
    private var vpnService: SusuVpnService? = null
    private var pendingConfig: String? = null
    private var pendingResult: MethodChannel.Result? = null

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            val localBinder = binder as? SusuVpnService.LocalBinder
            vpnService = localBinder?.getService()
            vpnService?.setStatusCallback { status ->
                activity.runOnUiThread {
                    flutterChannel?.invokeMethod("onStatusChanged", status)
                }
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            vpnService = null
        }
    }

    init {
        // 绑定Service
        val intent = Intent(activity, SusuVpnService::class.java)
        activity.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    fun setFlutterChannel(channel: MethodChannel) {
        flutterChannel = channel
    }

    /**
     * 启动VPN
     */
    fun startVpn(config: String, nodeName: String, result: MethodChannel.Result) {
        // 检查VPN权限
        val intent = VpnService.prepare(activity)
        if (intent != null) {
            // 需要用户授权
            pendingConfig = config
            pendingResult = result
            activity.startActivityForResult(intent, VPN_REQUEST_CODE)
        } else {
            // 已有权限，直接启动
            doStartVpn(config, nodeName, result)
        }
    }

    private fun doStartVpn(config: String, nodeName: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(activity, SusuVpnService::class.java).apply {
                action = SusuVpnService.ACTION_START
                putExtra(SusuVpnService.EXTRA_CONFIG, config)
                putExtra(SusuVpnService.EXTRA_NODE_NAME, nodeName)
            }
            activity.startService(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("START_FAILED", e.message, null)
        }
    }

    /**
     * 停止VPN
     */
    fun stopVpn(result: MethodChannel.Result) {
        try {
            val intent = Intent(activity, SusuVpnService::class.java).apply {
                action = SusuVpnService.ACTION_STOP
            }
            activity.startService(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_FAILED", e.message, null)
        }
    }

    /**
     * 获取流量统计
     */
    fun getStats(): Map<String, Long>? {
        return vpnService?.getTrafficStats()
    }

    /**
     * 处理VPN权限请求结果
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pendingConfig?.let { config ->
                    doStartVpn(config, "节点", pendingResult ?: return)
                }
            } else {
                pendingResult?.error("PERMISSION_DENIED", "用户拒绝VPN权限", null)
                flutterChannel?.invokeMethod("onError", "用户拒绝VPN授权")
            }
            pendingConfig = null
            pendingResult = null
        }
    }

    fun release() {
        try {
            activity.unbindService(serviceConnection)
        } catch (_: Exception) {}
    }
}

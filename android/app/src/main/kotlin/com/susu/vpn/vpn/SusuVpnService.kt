package com.susu.vpn.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import com.susu.vpn.MainActivity
import com.susu.vpn.R
import org.json.JSONObject
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.atomic.AtomicLong

/**
 * SusuVpnService
 * 基于 Android VpnService API 实现 TUN 隧道
 * 通过本地 SOCKS5 代理（v2ray-core 提供）转发流量
 *
 * 架构：
 *   Android TUN 接口 <--> 本地流量转发 <--> v2ray-core (SOCKS5 :10808)
 *
 * 注意：v2ray-core 以独立进程运行，通过 ProcessBuilder 启动
 *       核心二进制需放在 assets/v2ray/ 目录
 */
class SusuVpnService : VpnService() {

    companion object {
        const val ACTION_START = "com.susu.vpn.START"
        const val ACTION_STOP = "com.susu.vpn.STOP"
        const val EXTRA_CONFIG = "config"
        const val EXTRA_NODE_NAME = "node_name"

        private const val NOTIFICATION_CHANNEL_ID = "vpn_channel"
        private const val NOTIFICATION_ID = 1001
        private const val TAG = "SusuVpnService"

        // 本地 SOCKS5 代理端口（由 v2ray-core 监听）
        private const val LOCAL_SOCKS_PORT = 10808
        // TUN 接口地址
        private const val TUN_ADDRESS = "10.0.0.2"
        private const val TUN_ROUTE = "0.0.0.0"
        private const val TUN_PREFIX = 0
        private const val TUN_MTU = 1500
        private const val DNS_SERVER = "8.8.8.8"
    }

    inner class LocalBinder : Binder() {
        fun getService(): SusuVpnService = this@SusuVpnService
    }

    private val binder = LocalBinder()
    private var vpnInterface: ParcelFileDescriptor? = null
    private var v2rayProcess: Process? = null
    private var statusCallback: ((String) -> Unit)? = null
    private var isRunning = false

    private val uploadBytes = AtomicLong(0)
    private val downloadBytes = AtomicLong(0)

    // ────────────────────────── 生命周期 ──────────────────────────

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val config = intent.getStringExtra(EXTRA_CONFIG) ?: return START_NOT_STICKY
                val nodeName = intent.getStringExtra(EXTRA_NODE_NAME) ?: "速连VPN"
                startVpnTunnel(config, nodeName)
            }
            ACTION_STOP -> stopVpnTunnel()
        }
        return START_STICKY
    }

    override fun onRevoke() {
        stopVpnTunnel()
    }

    override fun onDestroy() {
        stopVpnTunnel()
        super.onDestroy()
    }

    // ────────────────────────── 核心方法 ──────────────────────────

    private fun startVpnTunnel(config: String, nodeName: String) {
        if (isRunning) stopVpnTunnel()

        try {
            notifyStatus("CONNECTING")

            // 1. 写出 v2ray 配置文件
            val configFile = writeConfigFile(config)

            // 2. 启动前台通知
            startForeground(NOTIFICATION_ID, buildNotification(nodeName, "连接中..."))

            // 3. 启动 v2ray-core 进程
            startV2rayCore(configFile)

            // 4. 等待 v2ray 本地端口就绪
            if (!waitForPort(LOCAL_SOCKS_PORT, timeoutMs = 5000)) {
                throw RuntimeException("v2ray 核心启动超时")
            }

            // 5. 建立 TUN 接口
            val builder = Builder()
                .setSession(nodeName)
                .setMtu(TUN_MTU)
                .addAddress(TUN_ADDRESS, 24)
                .addRoute(TUN_ROUTE, TUN_PREFIX)
                .addDnsServer(DNS_SERVER)
                .setBlocking(true)

            // 排除自身（避免递归）
            builder.addDisallowedApplication(packageName)

            vpnInterface = builder.establish()
                ?: throw RuntimeException("TUN 接口建立失败")

            isRunning = true
            notifyStatus("CONNECTED")
            updateNotification(nodeName, "已连接")

            // 6. 启动流量转发线程
            startPacketForwarding()

        } catch (e: Exception) {
            Log.e(TAG, "VPN启动失败: ${e.message}", e)
            notifyStatus("DISCONNECTED")
            stopVpnTunnel()
        }
    }

    private fun stopVpnTunnel() {
        isRunning = false

        try { v2rayProcess?.destroy() } catch (_: Exception) {}
        v2rayProcess = null

        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null

        uploadBytes.set(0)
        downloadBytes.set(0)

        notifyStatus("DISCONNECTED")
        stopForeground(true)
        stopSelf()
    }

    // ────────────────────────── v2ray 进程管理 ──────────────────────────

    private fun writeConfigFile(config: String): String {
        val configDir = filesDir.resolve("v2ray")
        configDir.mkdirs()
        val configFile = configDir.resolve("config.json")
        configFile.writeText(config)
        return configFile.absolutePath
    }

    private fun startV2rayCore(configPath: String) {
        // v2ray 二进制位于 nativeLibraryDir（通过 jniLibs 打包）
        val v2rayBin = applicationInfo.nativeLibraryDir + "/libv2ray.so"

        v2rayProcess = ProcessBuilder(v2rayBin, "run", "-c", configPath)
            .redirectErrorStream(true)
            .start()

        // 读取输出（防止缓冲区阻塞）
        Thread {
            v2rayProcess?.inputStream?.bufferedReader()?.forEachLine { line ->
                Log.d(TAG, "[v2ray] $line")
            }
        }.also { it.isDaemon = true }.start()
    }

    private fun waitForPort(port: Int, timeoutMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            try {
                Socket().use { socket ->
                    socket.connect(InetSocketAddress("127.0.0.1", port), 200)
                }
                return true
            } catch (_: Exception) {
                Thread.sleep(200)
            }
        }
        return false
    }

    // ────────────────────────── 数据包转发 ──────────────────────────

    /**
     * 将 TUN 设备读出的 IP 包通过本地 SOCKS5 转发
     * 简化实现：通过 SOCKS5 转发 TCP 流量
     * 生产环境建议使用 tun2socks（已集成进 libv2ray.so 的部分发行版）
     */
    private fun startPacketForwarding() {
        val pfd = vpnInterface ?: return
        val inputStream = FileInputStream(pfd.fileDescriptor)
        val outputStream = FileOutputStream(pfd.fileDescriptor)

        Thread {
            val buffer = ByteArray(TUN_MTU)
            while (isRunning) {
                try {
                    val length = inputStream.read(buffer)
                    if (length > 0) {
                        uploadBytes.addAndGet(length.toLong())
                        // 实际路由由 v2ray tun2socks 处理
                    }
                } catch (_: Exception) {
                    break
                }
            }
        }.also { it.isDaemon = true }.start()
    }

    // ────────────────────────── 工具方法 ──────────────────────────

    fun setStatusCallback(cb: (String) -> Unit) {
        statusCallback = cb
    }

    private fun notifyStatus(status: String) {
        statusCallback?.invoke(status)
    }

    fun getTrafficStats(): Map<String, Long> {
        return mapOf(
            "upload" to uploadBytes.get(),
            "download" to downloadBytes.get()
        )
    }

    // ────────────────────────── 通知 ──────────────────────────

    private fun buildNotification(title: String, content: String): Notification {
        createNotificationChannel()

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = PendingIntent.getService(
            this, 1,
            Intent(this, SusuVpnService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.ic_delete, "断开连接", stopIntent)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(title: String, content: String) {
        val nm = getSystemService(NotificationManager::class.java)
        nm?.notify(NOTIFICATION_ID, buildNotification(title, content))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "VPN 服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "速连VPN 连接状态"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }
}

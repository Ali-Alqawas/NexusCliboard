package com.nexusclip.clip

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import android.accessibilityservice.AccessibilityServiceInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * NexusClip - MainActivity
 * النشاط الرئيسي للتطبيق
 *
 * يدير الاتصال بين Flutter و Native Kotlin
 * Manages communication between Flutter and Native Kotlin
 *
 * المسؤوليات / Responsibilities:
 * - إنشاء قنوات Method Channels
 * - إدارة الصلاحيات (Overlay, Accessibility)
 * - تشغيل/إيقاف الخدمة الأمامية
 * - التحكم بالمقبض الجانبي
 */
class MainActivity : FlutterActivity() {

    companion object {
        // أسماء القنوات / Channel Names
        private const val METHOD_CHANNEL = "com.nexusclip.clip/methods"
        private const val EVENT_CHANNEL = "com.nexusclip.clip/events"
        private const val CLIPBOARD_CHANNEL = "com.nexusclip.clip/clipboard"

        // رموز طلب الصلاحيات / Permission Request Codes
        private const val OVERLAY_PERMISSION_REQUEST = 1001
        private const val ACCESSIBILITY_PERMISSION_REQUEST = 1002
    }

    // قنوات الاتصال / Communication Channels
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var clipboardChannel: MethodChannel? = null

    // مرسل الأحداث / Event Sink
    private var eventSink: EventChannel.EventSink? = null

    // =====================================================
    // دورة الحياة / Lifecycle
    // =====================================================

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // إنشاء قناة الأساليب الرئيسية / Setup main method channel
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // إدارة الخدمة / Service Management
                "startService" -> {
                    val success = startNexusClipService()
                    result.success(success)
                }
                "stopService" -> {
                    val success = stopNexusClipService()
                    result.success(success)
                }
                "isServiceRunning" -> {
                    result.success(isServiceRunning())
                }

                // الصلاحيات / Permissions
                "checkAllPermissions" -> {
                    val permissions = mapOf(
                        "overlay" to hasOverlayPermission(),
                        "accessibility" to hasAccessibilityPermission()
                    )
                    result.success(permissions)
                }
                "checkOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "checkAccessibilityPermission" -> {
                    result.success(hasAccessibilityPermission())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(null)
                }

                // المقبض الجانبي / Side Handle
                "showHandle" -> {
                    NexusClipService.showHandle()
                    result.success(true)
                }
                "hideHandle" -> {
                    NexusClipService.hideHandle()
                    result.success(true)
                }
                "setHandlePosition" -> {
                    val y = call.argument<Double>("y") ?: 0.5
                    NexusClipService.setHandlePosition(y.toFloat())
                    result.success(true)
                }

                // التحكم بالمؤشر / Cursor Control
                "moveCursor" -> {
                    val direction = call.argument<String>("direction") ?: "down"
                    val success = moveCursor(direction)
                    result.success(success)
                }
                "sendKeyEvent" -> {
                    val keyCode = call.argument<Int>("keyCode") ?: 0
                    val success = sendKeyEvent(keyCode)
                    result.success(success)
                }

                // معلومات الجهاز / Device Info
                "getDeviceInfo" -> {
                    result.success(getDeviceInfo())
                }

                else -> result.notImplemented()
            }
        }

        // إنشاء قناة الأحداث / Setup event channel
        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        )

        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // إنشاء قناة الحافظة / Setup clipboard channel
        clipboardChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CLIPBOARD_CHANNEL
        )

        clipboardChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getClipboardContent" -> {
                    result.success(getClipboardContent())
                }
                "setClipboardContent" -> {
                    val text = call.argument<String>("text") ?: ""
                    setClipboardContent(text)
                    result.success(true)
                }
                "getClipboardHistory" -> {
                    result.success(getClipboardHistory())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // إرسال تحديث الصلاحيات عند العودة للتطبيق
        sendPermissionsUpdate()
    }

    // =====================================================
    // إدارة الخدمة / Service Management
    // =====================================================

    private fun startNexusClipService(): Boolean {
        return try {
            if (!hasOverlayPermission()) {
                requestOverlayPermission()
                false
            } else {
                val serviceIntent = Intent(this, NexusClipService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun stopNexusClipService(): Boolean {
        return try {
            stopService(Intent(this, NexusClipService::class.java))
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun isServiceRunning(): Boolean {
        // يمكن تحسين هذا بالتحقق من الخدمة الفعلية
        return true
    }

    // =====================================================
    // الصلاحيات / Permissions
    // =====================================================

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
            }
        }
    }

    private fun hasAccessibilityPermission(): Boolean {
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK
        )

        for (service in enabledServices) {
            if (service.resolveInfo.serviceInfo.packageName == packageName) {
                return true
            }
        }
        return false
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivityForResult(intent, ACCESSIBILITY_PERMISSION_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            OVERLAY_PERMISSION_REQUEST -> {
                val granted = hasOverlayPermission()
                sendPermissionResult("overlay", granted)
                if (granted) {
                    // بدء الخدمة تلقائياً بعد منح الصلاحية
                    startNexusClipService()
                }
            }
            ACCESSIBILITY_PERMISSION_REQUEST -> {
                val granted = hasAccessibilityPermission()
                sendPermissionResult("accessibility", granted)
            }
        }
    }

    private fun sendPermissionResult(permission: String, granted: Boolean) {
        eventSink?.success(
            mapOf(
                "event" to "permissionResult",
                "permission" to permission,
                "granted" to granted
            )
        )
    }

    private fun sendPermissionsUpdate() {
        eventSink?.success(
            mapOf(
                "event" to "permissionsUpdated",
                "overlay" to hasOverlayPermission(),
                "accessibility" to hasAccessibilityPermission()
            )
        )
    }

    // =====================================================
    // التحكم بالمؤشر / Cursor Control
    // =====================================================

    private fun moveCursor(direction: String): Boolean {
        // يتم التعامل معه عبر Accessibility Service
        // يمكن إرسال الطلب للـ ClipboardAccessibilityService
        return try {
            val intent = Intent("com.nexusclip.clip.MOVE_CURSOR")
            intent.putExtra("direction", direction)
            sendBroadcast(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun sendKeyEvent(keyCode: Int): Boolean {
        return try {
            val intent = Intent("com.nexusclip.clip.KEY_EVENT")
            intent.putExtra("keyCode", keyCode)
            sendBroadcast(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    // =====================================================
    // الحافظة / Clipboard
    // =====================================================

    private fun getClipboardContent(): String? {
        return try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
            clipboard.primaryClip?.getItemAt(0)?.text?.toString()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun setClipboardContent(text: String) {
        try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
            val clip = android.content.ClipData.newPlainText("NexusClip", text)
            clipboard.setPrimaryClip(clip)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getClipboardHistory(): List<Map<String, Any>> {
        // يمكن تخزين السجل في SharedPreferences أو Database
        // حالياً نرجع قائمة فارغة
        return emptyList()
    }

    // =====================================================
    // معلومات الجهاز / Device Info
    // =====================================================

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "platform" to "android",
            "sdkVersion" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "brand" to Build.BRAND,
            "device" to Build.DEVICE,
            "isEmulator" to isEmulator()
        )
    }

    private fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.BRAND.startsWith("generic")
                || Build.DEVICE.startsWith("generic"))
    }
}

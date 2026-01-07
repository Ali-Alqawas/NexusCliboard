package com.nexusclip.clip

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.core.app.NotificationCompat

/**
 * NexusClipService - الحارس الصامت
 * The Silent Guardian - Foreground Service
 * 
 * هذه الخدمة تعمل 24/7 باستهلاك موارد أدنى (5-10MB RAM)
 * This service runs 24/7 with minimal resource consumption (5-10MB RAM)
 * 
 * المسؤوليات / Responsibilities:
 * - رسم المقبض الجانبي باستخدام WindowManager (Native XML)
 * - معالجة أحداث اللمس للمقبض
 * - إيقاظ Flutter Engine عند الحاجة
 * - إدارة UDP Socket للمزامنة مع Linux
 */
class NexusClipService : Service() {
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "nexusclip_service_channel"
        
        // حالة الخدمة الثابتة / Static service state
        private var instance: NexusClipService? = null
        private var handleVisible = true
        private var handlePositionY = 0.5f
        
        // وظائف ثابتة للتحكم من Flutter
        // Static functions for Flutter control
        fun showHandle() {
            instance?.showHandleView()
        }
        
        fun hideHandle() {
            instance?.hideHandleView()
        }
        
        fun setHandlePosition(y: Float) {
            handlePositionY = y.coerceIn(0.1f, 0.9f)
            instance?.updateHandlePosition()
        }
    }
    
    private lateinit var windowManager: WindowManager
    private var handleView: View? = null
    private var handleParams: WindowManager.LayoutParams? = null
    
    // موضع السحب / Drag position
    private var initialY = 0
    private var initialTouchY = 0f
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // إنشاء المقبض الجانبي
        // Create side handle
        createHandle()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        removeHandle()
    }
    
    // =====================================================
    // الإشعارات / Notifications
    // =====================================================
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_channel_description)
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.service_notification_title))
            .setContentText(getString(R.string.service_notification_text))
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    // =====================================================
    // المقبض الجانبي Native / Native Side Handle
    // =====================================================
    
    private fun createHandle() {
        if (handleView != null) return
        
        // إنشاء View المقبض برمجياً
        // Create handle view programmatically
        handleView = createHandleView()
        
        // إعدادات النافذة / Window parameters
        handleParams = WindowManager.LayoutParams().apply {
            width = dpToPx(8)
            height = dpToPx(100)
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
            format = PixelFormat.TRANSLUCENT
            gravity = Gravity.END or Gravity.TOP
            
            // حساب موضع Y بناءً على النسبة المئوية
            // Calculate Y position based on percentage
            val displayMetrics = resources.displayMetrics
            y = (displayMetrics.heightPixels * handlePositionY).toInt() - height / 2
        }
        
        setupHandleTouchListener()
        
        try {
            windowManager.addView(handleView, handleParams)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun createHandleView(): View {
        // إنشاء FrameLayout كحاوية
        // Create FrameLayout as container
        return FrameLayout(this).apply {
            // خلفية شفافة مع لون Golden Bronze
            // Transparent background with Golden Bronze color
            setBackgroundColor(Color.parseColor("#80B48C69"))
            
            // إضافة استدارة للحواف
            // Add rounded corners
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(Color.parseColor("#B48C69"))
                cornerRadii = floatArrayOf(
                    dpToPx(4f), dpToPx(4f), // أعلى يسار
                    0f, 0f,                  // أعلى يمين
                    0f, 0f,                  // أسفل يمين
                    dpToPx(4f), dpToPx(4f)  // أسفل يسار
                )
                alpha = 180
            }
        }
    }
    
    private fun setupHandleTouchListener() {
        handleView?.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialY = handleParams?.y ?: 0
                    initialTouchY = event.rawY
                    triggerHapticFeedback()
                    true
                }
                
                MotionEvent.ACTION_MOVE -> {
                    // السحب العمودي لتغيير موضع المقبض
                    // Vertical drag to change handle position
                    handleParams?.let { params ->
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager.updateViewLayout(handleView, params)
                    }
                    true
                }
                
                MotionEvent.ACTION_UP -> {
                    val deltaY = kotlin.math.abs(event.rawY - initialTouchY)
                    
                    if (deltaY < dpToPx(10f)) {
                        // نقرة قصيرة - فتح الشريط الجانبي
                        // Short click - open side panel
                        triggerHapticFeedback()
                        openFlutterOverlay()
                    } else {
                        // تم السحب - حفظ الموضع الجديد
                        // Dragged - save new position
                        val displayMetrics = resources.displayMetrics
                        handlePositionY = (handleParams?.y?.toFloat() ?: 0f) / displayMetrics.heightPixels
                    }
                    true
                }
                
                else -> false
            }
        }
    }
    
    private fun showHandleView() {
        if (handleView == null) {
            createHandle()
        } else {
            handleView?.visibility = View.VISIBLE
        }
        handleVisible = true
    }
    
    private fun hideHandleView() {
        handleView?.visibility = View.GONE
        handleVisible = false
    }
    
    private fun updateHandlePosition() {
        handleParams?.let { params ->
            val displayMetrics = resources.displayMetrics
            params.y = (displayMetrics.heightPixels * handlePositionY).toInt() - params.height / 2
            try {
                windowManager.updateViewLayout(handleView, params)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    private fun removeHandle() {
        handleView?.let {
            try {
                windowManager.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        handleView = null
    }
    
    // =====================================================
    // إيقاظ Flutter / Wake Flutter
    // =====================================================
    
    private fun openFlutterOverlay() {
        // فتح OverlayActivity التي تحتوي على Flutter UI
        // Open OverlayActivity containing Flutter UI
        val intent = Intent(this, OverlayActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        startActivity(intent)
    }
    
    // =====================================================
    // الاهتزاز اللمسي / Haptic Feedback
    // =====================================================
    
    private fun triggerHapticFeedback() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(10)
        }
    }
    
    // =====================================================
    // أدوات مساعدة / Utilities
    // =====================================================
    
    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
    
    private fun dpToPx(dp: Float): Float {
        return dp * resources.displayMetrics.density
    }
}

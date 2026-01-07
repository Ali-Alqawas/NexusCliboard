package com.nexusclip.clip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BootReceiver - مستقبل إعادة التشغيل
 * Boot Broadcast Receiver
 * 
 * يبدأ خدمة NexusClip تلقائياً عند تشغيل الجهاز
 * Automatically starts NexusClip service on device boot
 */
class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            context?.let { ctx ->
                // التحقق من إعدادات التشغيل التلقائي
                // Check auto-start settings
                val prefs = ctx.getSharedPreferences("nexusclip_prefs", Context.MODE_PRIVATE)
                val autoStart = prefs.getBoolean("auto_start_on_boot", true)
                
                if (autoStart) {
                    // بدء الخدمة
                    // Start service
                    val serviceIntent = Intent(ctx, NexusClipService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        ctx.startForegroundService(serviceIntent)
                    } else {
                        ctx.startService(serviceIntent)
                    }
                }
            }
        }
    }
}

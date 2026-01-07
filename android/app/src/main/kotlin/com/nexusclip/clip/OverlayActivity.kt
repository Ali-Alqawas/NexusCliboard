package com.nexusclip.clip

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * OverlayActivity - نشاط Flutter العائم
 * Flutter Overlay Activity
 * 
 * يُستخدم لعرض الشريط الجانبي والخزنة
 * Used to display side panel and vault
 * 
 * خصائص النافذة / Window Properties:
 * - شفافة جزئياً لتأثير Glassmorphism
 * - قابلة للإغلاق بالنقر خارجها
 * - لا تظهر في قائمة التطبيقات الأخيرة
 */
class OverlayActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // إعدادات النافذة الشفافة
        // Transparent window settings
        window.apply {
            // خلفية شفافة / Transparent background
            setBackgroundDrawableResource(android.R.color.transparent)
            
            // السماح بالتعتيم للتأثيرات البصرية
            // Allow dimming for visual effects
            addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            setDimAmount(0.5f)
            
            // خصائص إضافية / Additional properties
            attributes = attributes.apply {
                // جعل النافذة أعلى من التطبيقات الأخرى
                // Make window above other apps
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // تهيئة Flutter بنقطة الدخول overlay
        // Initialize Flutter with overlay entry point
        // سيتم استخدام overlay_main.dart
    }
    
    override fun getDartEntrypointFunctionName(): String {
        // نقطة الدخول لواجهة الـ Overlay
        // Entry point for Overlay interface
        return "overlayMain"
    }
    
    override fun onBackPressed() {
        super.onBackPressed()
        // الإغلاق السلس
        // Smooth close
        overridePendingTransition(0, android.R.anim.fade_out)
    }
    
    override fun finish() {
        super.finish()
        overridePendingTransition(0, android.R.anim.fade_out)
    }
}

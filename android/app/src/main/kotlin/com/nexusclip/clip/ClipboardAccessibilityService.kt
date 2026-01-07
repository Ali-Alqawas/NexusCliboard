package com.nexusclip.clip

import android.accessibilityservice.AccessibilityService
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * ClipboardAccessibilityService - خدمة الوصول للحافظة
 * Clipboard Accessibility Service
 * 
 * المسؤوليات / Responsibilities:
 * - مراقبة أحداث النسخ والتحديد على مستوى النظام
 * - التقاط محتوى الحافظة تلقائياً
 * - التحكم بالمؤشر عبر أحداث DPAD
 * - حفظ سجل الحافظة (آخر 100 عنصر)
 */
class ClipboardAccessibilityService : AccessibilityService() {
    
    companion object {
        private var instance: ClipboardAccessibilityService? = null
        
        // سجل الحافظة / Clipboard History
        private val clipboardHistory = mutableListOf<ClipboardItem>()
        private const val MAX_HISTORY_SIZE = 100
        
        // آخر محتوى منسوخ / Last copied content
        private var lastClipboardContent: String = ""
        
        /**
         * إرسال حدث زر للتحكم بالمؤشر
         * Send key event for cursor control
         */
        fun sendKeyEvent(keyCode: Int) {
            instance?.performKeyAction(keyCode)
        }
        
        /**
         * الحصول على آخر محتوى منسوخ
         * Get last clipboard content
         */
        fun getLastClipboardContent(): String = lastClipboardContent
        
        /**
         * الحصول على سجل الحافظة
         * Get clipboard history
         */
        fun getClipboardHistory(): List<Map<String, Any?>> {
            return clipboardHistory.map { it.toMap() }
        }
        
        /**
         * إضافة عنصر للسجل
         * Add item to history
         */
        fun addToHistory(content: String, type: String = "text") {
            if (content.isBlank() || content == lastClipboardContent) return
            
            lastClipboardContent = content
            
            val item = ClipboardItem(
                content = content,
                type = type,
                timestamp = System.currentTimeMillis(),
                isPinned = false,
                isSecure = type == "password"
            )
            
            // إضافة في البداية (الأحدث أولاً)
            // Add at beginning (newest first)
            clipboardHistory.add(0, item)
            
            // الحفاظ على الحد الأقصى للسجل
            // Maintain max history size
            if (clipboardHistory.size > MAX_HISTORY_SIZE) {
                // حذف العناصر غير المثبتة القديمة
                // Remove old unpinned items
                val toRemove = clipboardHistory
                    .filter { !it.isPinned }
                    .takeLast(clipboardHistory.size - MAX_HISTORY_SIZE)
                clipboardHistory.removeAll(toRemove)
            }
        }
    }
    
    private var clipboardManager: ClipboardManager? = null
    private var lastProcessedClipTime: Long = 0
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        // تهيئة مدير الحافظة
        // Initialize clipboard manager
        clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        
        // مراقبة تغييرات الحافظة
        // Monitor clipboard changes
        clipboardManager?.addPrimaryClipChangedListener {
            processClipboardChange()
        }
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        // الخدمة متصلة وجاهزة
        // Service connected and ready
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            when (it.eventType) {
                AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED -> {
                    // تم تحديد نص
                    // Text selected
                    handleTextSelection(it)
                }
                
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    // تغير محتوى النافذة
                    // Window content changed
                }
                
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                    // تغير نص في حقل إدخال
                    // Text changed in input field
                }
                
                else -> {}
            }
        }
    }
    
    override fun onInterrupt() {
        // تم مقاطعة الخدمة
        // Service interrupted
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
    
    // =====================================================
    // معالجة الحافظة / Clipboard Processing
    // =====================================================
    
    private fun processClipboardChange() {
        // تجنب المعالجة المتكررة
        // Avoid duplicate processing
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastProcessedClipTime < 500) return
        lastProcessedClipTime = currentTime
        
        try {
            val clipData = clipboardManager?.primaryClip
            if (clipData != null && clipData.itemCount > 0) {
                val item = clipData.getItemAt(0)
                val text = item.coerceToText(this).toString()
                
                if (text.isNotBlank()) {
                    val type = classifyContent(text)
                    addToHistory(text, type)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun handleTextSelection(event: AccessibilityEvent) {
        // يمكن استخدام هذا لالتقاط النص المحدد
        // Can be used to capture selected text
        val selectedText = event.text?.joinToString("") ?: ""
        if (selectedText.length in 1..1000) {
            // نص معقول للحفظ
            // Reasonable text to save
        }
    }
    
    // =====================================================
    // محرك التصنيف الذكي / Smart Classification Engine
    // =====================================================
    
    private fun classifyContent(content: String): String {
        // روابط / URLs
        if (content.matches(Regex("^https?://.*"))) {
            return "link"
        }
        
        // بريد إلكتروني / Email
        if (content.matches(Regex("^[^@]+@[^@]+\\.[^@]+$"))) {
            return "email"
        }
        
        // أكواد برمجية / Code
        val codePatterns = listOf(
            "\\b(void|class|function|const|var|let|def|import|return|if|else|for|while)\\b",
            "[{};]",
            "\\b(public|private|protected|static)\\b",
            "\\b(int|string|bool|float|double|List|Map)\\b"
        )
        for (pattern in codePatterns) {
            if (content.contains(Regex(pattern))) {
                return "code"
            }
        }
        
        // كلمات مرور محتملة / Possible passwords
        if (content.length in 8..32 && !content.contains(" ")) {
            val hasUppercase = content.any { it.isUpperCase() }
            val hasLowercase = content.any { it.isLowerCase() }
            val hasDigit = content.any { it.isDigit() }
            val hasSpecial = content.any { !it.isLetterOrDigit() }
            
            if ((hasUppercase && hasLowercase && hasDigit) ||
                (hasDigit && hasSpecial) ||
                content.matches(Regex(".*[!@#\$%^&*(),.?\":{}|<>].*"))) {
                return "password"
            }
        }
        
        // رقم هاتف / Phone number
        if (content.matches(Regex("^[+]?[0-9\\s-]{10,15}$"))) {
            return "phone"
        }
        
        // نص عادي / Plain text
        return "text"
    }
    
    // =====================================================
    // التحكم بالمؤشر / Cursor Control
    // =====================================================
    
    private fun performKeyAction(keyCode: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // استخدام dispatchGesture للتحكم الدقيق
            // Use dispatchGesture for precise control
        }
        
        // إرسال حدث الزر
        // Send key event
        val downTime = SystemClock.uptimeMillis()
        val eventTime = SystemClock.uptimeMillis()
        
        val downEvent = KeyEvent(downTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0)
        val upEvent = KeyEvent(downTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0)
        
        // محاولة إرسال الحدث للعنصر المركز
        // Try to send event to focused element
        val rootNode = rootInActiveWindow
        if (rootNode != null) {
            val focusedNode = findFocusedNode(rootNode)
            focusedNode?.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
        }
    }
    
    private fun findFocusedNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isFocused) {
            return node
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val focused = findFocusedNode(child)
            if (focused != null) {
                return focused
            }
        }
        
        return null
    }
    
    // =====================================================
    // نموذج عنصر الحافظة / Clipboard Item Model
    // =====================================================
    
    data class ClipboardItem(
        val content: String,
        val type: String,
        val timestamp: Long,
        var isPinned: Boolean = false,
        val isSecure: Boolean = false
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "content" to if (isSecure) maskContent() else content,
            "type" to type,
            "timestamp" to timestamp,
            "isPinned" to isPinned,
            "isSecure" to isSecure
        )
        
        private fun maskContent(): String {
            return if (content.length > 4) {
                "*".repeat(content.length - 4) + content.takeLast(4)
            } else {
                "*".repeat(content.length)
            }
        }
    }
}

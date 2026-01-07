import 'package:hive/hive.dart';

part 'clip_item.g.dart';

/// NexusClip - نموذج عنصر الحافظة
/// Clipboard Item Model
///
/// يمثل عنصر واحد في سجل الحافظة
/// Represents a single item in clipboard history
@HiveType(typeId: 0)
class ClipItem extends HiveObject {
  /// معرف فريد للعنصر
  /// Unique identifier
  @HiveField(0)
  final String id;

  /// محتوى العنصر
  /// Item content
  @HiveField(1)
  String content;

  /// نوع المحتوى (text, code, link, password, email, phone, template)
  /// Content type
  @HiveField(2)
  final String type;

  /// وقت الإنشاء
  /// Creation timestamp
  @HiveField(3)
  final DateTime createdAt;

  /// وقت آخر استخدام
  /// Last used timestamp
  @HiveField(4)
  DateTime lastUsedAt;

  /// هل العنصر مثبت
  /// Is item pinned
  @HiveField(5)
  bool isPinned;

  /// هل العنصر آمن (كلمة مرور)
  /// Is item secure (password)
  @HiveField(6)
  bool isSecure;

  /// عدد مرات الاستخدام
  /// Usage count
  @HiveField(7)
  int usageCount;

  /// تسمية مخصصة (للقوالب)
  /// Custom label (for templates)
  @HiveField(8)
  String? label;

  /// اسم التطبيق المصدر
  /// Source app name
  @HiveField(9)
  String? sourceApp;

  /// تصنيف فرعي (لغة البرمجة للكود مثلاً)
  /// Sub-category (programming language for code)
  @HiveField(10)
  String? subType;

  /// هل تم حذفه (حذف ناعم)
  /// Is deleted (soft delete)
  @HiveField(11)
  bool isDeleted;

  /// المحتوى المشفر (للعناصر الآمنة)
  /// Encrypted content (for secure items)
  @HiveField(12)
  String? encryptedContent;

  ClipItem({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
    DateTime? lastUsedAt,
    this.isPinned = false,
    this.isSecure = false,
    this.usageCount = 0,
    this.label,
    this.sourceApp,
    this.subType,
    this.isDeleted = false,
    this.encryptedContent,
  }) : lastUsedAt = lastUsedAt ?? createdAt;

  /// إنشاء عنصر جديد من نص
  /// Create new item from text
  factory ClipItem.fromText(String text, {String? sourceApp}) {
    final type = _classifyContent(text);
    final id = '${DateTime.now().millisecondsSinceEpoch}_${text.hashCode.abs()}';
    
    return ClipItem(
      id: id,
      content: text,
      type: type,
      createdAt: DateTime.now(),
      sourceApp: sourceApp,
      subType: type == 'code' ? _detectProgrammingLanguage(text) : null,
      isSecure: type == 'password',
    );
  }

  /// إنشاء قالب جديد
  /// Create new template
  factory ClipItem.template(String content, String label) {
    return ClipItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_template',
      content: content,
      type: 'template',
      createdAt: DateTime.now(),
      label: label,
      isPinned: true,
    );
  }

  /// تصنيف المحتوى تلقائياً
  /// Classify content automatically
  static String _classifyContent(String content) {
    // روابط / URLs
    if (RegExp(r'^https?://').hasMatch(content)) {
      return 'link';
    }

    // بريد إلكتروني / Email
    if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(content.trim())) {
      return 'email';
    }

    // رقم هاتف / Phone
    if (RegExp(r'^[+]?[\d\s-]{10,15}$').hasMatch(content.trim())) {
      return 'phone';
    }

    // أكواد برمجية / Code
    final codePatterns = [
      r'\b(void|class|function|const|var|let|def|import|return|if|else|for|while|switch|case)\b',
      r'[{};]',
      r'\b(public|private|protected|static|final|abstract)\b',
      r'\b(int|string|bool|float|double|List|Map|Set|String|Int|Boolean)\b',
      r'^\s*(import|from|package|require|include)\b',
      r'=>|->|\$\{|\$\w+',
    ];

    for (final pattern in codePatterns) {
      if (RegExp(pattern).hasMatch(content)) {
        return 'code';
      }
    }

    // كلمات مرور محتملة / Possible passwords
    if (content.length >= 8 && content.length <= 64 && !content.contains(' ')) {
      final hasUppercase = content.contains(RegExp(r'[A-Z]'));
      final hasLowercase = content.contains(RegExp(r'[a-z]'));
      final hasDigit = content.contains(RegExp(r'[0-9]'));
      final hasSpecial = content.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      if ((hasUppercase && hasLowercase && hasDigit) ||
          (hasDigit && hasSpecial) ||
          (hasUppercase && hasLowercase && hasSpecial)) {
        return 'password';
      }
    }

    return 'text';
  }

  /// كشف لغة البرمجة
  /// Detect programming language
  static String? _detectProgrammingLanguage(String content) {
    if (content.contains('flutter') || content.contains('Widget') || content.contains('BuildContext')) {
      return 'dart';
    }
    if (content.contains('func ') || content.contains('package main')) {
      return 'go';
    }
    if (content.contains('def ') || content.contains('import ') && content.contains(':')) {
      return 'python';
    }
    if (content.contains('function') || content.contains('=>') || content.contains('const ')) {
      return 'javascript';
    }
    if (content.contains('public class') || content.contains('private void')) {
      return 'java';
    }
    if (content.contains('fun ') || content.contains('val ') || content.contains('var ')) {
      return 'kotlin';
    }
    if (content.contains('#include') || content.contains('std::')) {
      return 'cpp';
    }
    if (content.contains('<?php')) {
      return 'php';
    }
    if (content.contains('<html') || content.contains('<div') || content.contains('<span')) {
      return 'html';
    }
    if (content.contains('{') && content.contains(':') && content.contains(';')) {
      return 'css';
    }
    return null;
  }

  /// تحديث وقت الاستخدام
  /// Update usage time
  void markAsUsed() {
    lastUsedAt = DateTime.now();
    usageCount++;
    save();
  }

  /// تبديل التثبيت
  /// Toggle pin
  void togglePin() {
    isPinned = !isPinned;
    save();
  }

  /// حذف ناعم
  /// Soft delete
  void softDelete() {
    isDeleted = true;
    save();
  }

  /// استعادة العنصر
  /// Restore item
  void restore() {
    isDeleted = false;
    save();
  }

  /// الحصول على المحتوى المعروض (مخفي للكلمات السرية)
  /// Get display content (masked for passwords)
  String get displayContent {
    if (isSecure && encryptedContent != null) {
      return '•' * 8 + content.substring(content.length - 4.clamp(0, content.length));
    }
    return content;
  }

  /// الحصول على وصف مختصر
  /// Get short description
  String get shortDescription {
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  /// الحصول على أيقونة النوع
  /// Get type icon
  String get typeIcon {
    switch (type) {
      case 'link':
        return '🔗';
      case 'code':
        return '💻';
      case 'password':
        return '🔐';
      case 'email':
        return '📧';
      case 'phone':
        return '📱';
      case 'template':
        return '📝';
      default:
        return '📋';
    }
  }

  /// تحويل إلى خريطة
  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUsedAt': lastUsedAt.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'isSecure': isSecure,
      'usageCount': usageCount,
      'label': label,
      'sourceApp': sourceApp,
      'subType': subType,
      'isDeleted': isDeleted,
    };
  }

  /// إنشاء من خريطة
  /// Create from map
  factory ClipItem.fromMap(Map<String, dynamic> map) {
    return ClipItem(
      id: map['id'] as String,
      content: map['content'] as String,
      type: map['type'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastUsedAt: DateTime.fromMillisecondsSinceEpoch(map['lastUsedAt'] as int),
      isPinned: map['isPinned'] as bool? ?? false,
      isSecure: map['isSecure'] as bool? ?? false,
      usageCount: map['usageCount'] as int? ?? 0,
      label: map['label'] as String?,
      sourceApp: map['sourceApp'] as String?,
      subType: map['subType'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'ClipItem(id: $id, type: $type, content: $shortDescription)';
  }
}

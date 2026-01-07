import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// NexusClip - خدمة التشفير
/// Encryption Service
///
/// تدير تشفير وفك تشفير البيانات الحساسة باستخدام AES-256
/// Manages encryption and decryption of sensitive data using AES-256
class EncryptionService {
  // Singleton pattern
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // =====================================================
  // ثوابت / Constants
  // =====================================================

  static const String _keyStorageKey = 'nexusclip_encryption_key';
  static const String _ivStorageKey = 'nexusclip_encryption_iv';
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  // التخزين الآمن / Secure Storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // مفتاح التشفير / Encryption key
  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // =====================================================
  // التهيئة / Initialization
  // =====================================================

  /// تهيئة خدمة التشفير
  /// Initialize encryption service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // محاولة استرجاع المفتاح المحفوظ
      String? storedKey = await _secureStorage.read(key: _keyStorageKey);
      String? storedIv = await _secureStorage.read(key: _ivStorageKey);

      if (storedKey != null && storedIv != null) {
        // استخدام المفتاح المحفوظ
        _key = encrypt.Key(base64Decode(storedKey));
        _iv = encrypt.IV(base64Decode(storedIv));
      } else {
        // إنشاء مفتاح جديد
        await _generateAndStoreKey();
      }

      _encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('Encryption service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing encryption service: $e');
      }
      // إنشاء مفتاح جديد في حالة الخطأ
      await _generateAndStoreKey();
      _encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
      _isInitialized = true;
    }
  }

  /// إنشاء وحفظ مفتاح جديد
  /// Generate and store new key
  Future<void> _generateAndStoreKey() async {
    // إنشاء مفتاح عشوائي
    final random = Random.secure();
    final keyBytes = Uint8List(_keyLength);
    final ivBytes = Uint8List(_ivLength);

    for (var i = 0; i < _keyLength; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    for (var i = 0; i < _ivLength; i++) {
      ivBytes[i] = random.nextInt(256);
    }

    _key = encrypt.Key(keyBytes);
    _iv = encrypt.IV(ivBytes);

    // حفظ المفتاح في التخزين الآمن
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64Encode(keyBytes),
    );
    await _secureStorage.write(
      key: _ivStorageKey,
      value: base64Encode(ivBytes),
    );
  }

  // =====================================================
  // التشفير وفك التشفير / Encryption & Decryption
  // =====================================================

  /// تشفير نص
  /// Encrypt text
  String encryptText(String plainText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Encryption error: $e');
      }
      rethrow;
    }
  }

  /// فك تشفير نص
  /// Decrypt text
  String decryptText(String encryptedText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final decrypted = _encrypter!.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Decryption error: $e');
      }
      rethrow;
    }
  }

  /// التحقق من صحة التشفير
  /// Verify encryption
  bool verifyEncryption(String originalText, String encryptedText) {
    try {
      final decrypted = decryptText(encryptedText);
      return decrypted == originalText;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // التجزئة / Hashing
  // =====================================================

  /// إنشاء تجزئة SHA-256
  /// Generate SHA-256 hash
  String hashText(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// إنشاء تجزئة MD5 (للتحقق فقط، ليس للأمان)
  /// Generate MD5 hash (for verification only, not for security)
  String md5Hash(String text) {
    final bytes = utf8.encode(text);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// التحقق من التجزئة
  /// Verify hash
  bool verifyHash(String text, String hash) {
    return hashText(text) == hash;
  }

  // =====================================================
  // إدارة المفاتيح / Key Management
  // =====================================================

  /// إعادة إنشاء المفتاح (تحذير: سيفقد البيانات المشفرة!)
  /// Regenerate key (Warning: will lose encrypted data!)
  Future<void> regenerateKey() async {
    await _generateAndStoreKey();
    _encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
  }

  /// التحقق من وجود المفتاح
  /// Check if key exists
  Future<bool> hasEncryptionKey() async {
    final key = await _secureStorage.read(key: _keyStorageKey);
    return key != null;
  }

  /// حذف المفتاح
  /// Delete key
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
    _key = null;
    _iv = null;
    _encrypter = null;
    _isInitialized = false;
  }

  // =====================================================
  // أدوات مساعدة / Utilities
  // =====================================================

  /// إنشاء كلمة مرور عشوائية
  /// Generate random password
  String generateRandomPassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecial = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSpecial) chars += special;

    if (chars.isEmpty) chars = lowercase + numbers;

    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// إخفاء النص (للعرض)
  /// Mask text (for display)
  String maskText(String text, {int visibleChars = 4}) {
    if (text.length <= visibleChars) {
      return '•' * text.length;
    }
    return '•' * (text.length - visibleChars) + text.substring(text.length - visibleChars);
  }

  /// التحقق من قوة كلمة المرور
  /// Check password strength
  PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // الطول
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // التنوع
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

/// قوة كلمة المرور
/// Password strength enum
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

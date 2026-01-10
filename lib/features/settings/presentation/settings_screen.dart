import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/platform_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../vault/widgets/glassmorphic_container.dart';
import '../../sync/presentation/sync_screen.dart';

/// NexusClip - شاشة الإعدادات الكاملة
/// Complete Settings Screen
///
/// تحتوي على جميع إعدادات التطبيق
/// Contains all app settings
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PlatformService _platformService = PlatformService();
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();
  final EncryptionService _encryptionService = EncryptionService();

  // إعدادات التطبيق / App Settings
  bool _autoStartService = true;
  bool _showHandleOnStart = true;
  bool _hapticFeedback = true;
  bool _autoDetectType = true;
  bool _syncEnabled = false;
  bool _biometricAuth = false;
  int _maxHistoryItems = 50;
  double _handlePosition = 0.5;

  // حالة الصلاحيات / Permission States
  bool _overlayPermission = false;
  bool _accessibilityPermission = false;

  // إحصائيات / Statistics
  Map<String, int> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
    _loadStatistics();
  }

  Future<void> _loadSettings() async {
    try {
      if (!_databaseService.isInitialized) {
        await _databaseService.initialize();
      }

      setState(() {
        _autoStartService = _databaseService.getSetting<bool>(
          'auto_start_service',
          defaultValue: true,
        ) ?? true;
        _showHandleOnStart = _databaseService.getSetting<bool>(
          'show_handle_on_start',
          defaultValue: true,
        ) ?? true;
        _hapticFeedback = _databaseService.getSetting<bool>(
          'haptic_feedback',
          defaultValue: true,
        ) ?? true;
        _autoDetectType = _databaseService.getSetting<bool>(
          'auto_detect_type',
          defaultValue: true,
        ) ?? true;
        _syncEnabled = _databaseService.getSetting<bool>(
          'sync_enabled',
          defaultValue: false,
        ) ?? false;
        _biometricAuth = _databaseService.getSetting<bool>(
          'biometric_auth',
          defaultValue: false,
        ) ?? false;
        _maxHistoryItems = _databaseService.getSetting<int>(
          'max_history_items',
          defaultValue: 50,
        ) ?? 50;
        _handlePosition = _databaseService.getSetting<double>(
          'handle_position',
          defaultValue: 0.5,
        ) ?? 0.5;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final permissions = await _platformService.checkAllPermissions();
      if (mounted) {
        setState(() {
          _overlayPermission = permissions['overlay'] ?? false;
          _accessibilityPermission = permissions['accessibility'] ?? false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking permissions: $e');
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _statistics = _databaseService.getStatistics();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading statistics: $e');
      }
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      await _databaseService.saveSetting(key, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving setting: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم الصلاحيات / Permissions Section
          _buildSection(
            title: 'الصلاحيات',
            titleEn: 'Permissions',
            icon: Icons.security_rounded,
            children: [
              _buildPermissionTile(
                title: 'العرض فوق التطبيقات',
                subtitle: 'مطلوب للشريط العائم',
                isEnabled: _overlayPermission,
                onTap: () => _platformService.requestOverlayPermission(),
              ),
              _buildPermissionTile(
                title: 'خدمة الوصول',
                subtitle: 'مطلوب لمراقبة الحافظة',
                isEnabled: _accessibilityPermission,
                onTap: () => _platformService.requestAccessibilityPermission(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم الخدمة / Service Section
          _buildSection(
            title: 'الخدمة',
            titleEn: 'Service',
            icon: Icons.play_circle_outline_rounded,
            children: [
              _buildSwitchTile(
                title: 'بدء تلقائي',
                subtitle: 'تشغيل الخدمة عند إقلاع الجهاز',
                value: _autoStartService,
                onChanged: (value) {
                  setState(() => _autoStartService = value);
                  _saveSetting('auto_start_service', value);
                },
              ),
              _buildSwitchTile(
                title: 'إظهار المقبض',
                subtitle: 'إظهار الشريط العائم عند بدء الخدمة',
                value: _showHandleOnStart,
                onChanged: (value) {
                  setState(() => _showHandleOnStart = value);
                  _saveSetting('show_handle_on_start', value);
                },
              ),
              _buildSliderTile(
                title: 'موضع المقبض',
                value: _handlePosition,
                onChanged: (value) {
                  setState(() => _handlePosition = value);
                  _saveSetting('handle_position', value);
                  _platformService.setHandlePosition(value);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم الحافظة / Clipboard Section
          _buildSection(
            title: 'الحافظة',
            titleEn: 'Clipboard',
            icon: Icons.content_paste_rounded,
            children: [
              _buildSwitchTile(
                title: 'كشف النوع تلقائياً',
                subtitle: 'تصنيف المحتوى المنسوخ تلقائياً',
                value: _autoDetectType,
                onChanged: (value) {
                  setState(() => _autoDetectType = value);
                  _saveSetting('auto_detect_type', value);
                },
              ),
              _buildDropdownTile(
                title: 'الحد الأقصى للسجل',
                subtitle: '$_maxHistoryItems عنصر',
                value: _maxHistoryItems,
                items: [25, 50, 100, 200, 500],
                onChanged: (value) {
                  setState(() => _maxHistoryItems = value!);
                  _saveSetting('max_history_items', value);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم المزامنة / Sync Section
          _buildSection(
            title: 'المزامنة',
            titleEn: 'Sync',
            icon: Icons.sync_rounded,
            children: [
              _buildSwitchTile(
                title: 'تفعيل المزامنة',
                subtitle: 'مزامنة مع أجهزة Linux',
                value: _syncEnabled,
                onChanged: (value) async {
                  setState(() => _syncEnabled = value);
                  _saveSetting('sync_enabled', value);
                  if (value) {
                    await _syncService.start();
                  } else {
                    await _syncService.stop();
                  }
                },
              ),
              if (_syncEnabled)
                _buildSyncStatus(),
              _buildActionTile(
                title: 'إعدادات المزامنة المتقدمة',
                subtitle: 'عرض الأجهزة المكتشفة والتحكم',
                icon: Icons.settings_ethernet_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SyncScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم الأمان / Security Section
          _buildSection(
            title: 'الأمان',
            titleEn: 'Security',
            icon: Icons.lock_outline_rounded,
            children: [
              _buildSwitchTile(
                title: 'المصادقة البيومترية',
                subtitle: 'استخدام البصمة للوصول للخزنة الآمنة',
                value: _biometricAuth,
                onChanged: (value) {
                  setState(() => _biometricAuth = value);
                  _saveSetting('biometric_auth', value);
                },
              ),
              _buildActionTile(
                title: 'إعادة إنشاء مفتاح التشفير',
                subtitle: 'تحذير: سيفقد البيانات المشفرة!',
                icon: Icons.key_rounded,
                color: AppColors.warning,
                onTap: _showRegenerateKeyDialog,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم التجربة / Experience Section
          _buildSection(
            title: 'التجربة',
            titleEn: 'Experience',
            icon: Icons.tune_rounded,
            children: [
              _buildSwitchTile(
                title: 'الاهتزاز اللمسي',
                subtitle: 'اهتزاز عند التفاعل',
                value: _hapticFeedback,
                onChanged: (value) {
                  setState(() => _hapticFeedback = value);
                  _saveSetting('haptic_feedback', value);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم الإحصائيات / Statistics Section
          _buildSection(
            title: 'الإحصائيات',
            titleEn: 'Statistics',
            icon: Icons.bar_chart_rounded,
            children: [
              _buildStatisticsTile(),
            ],
          ),

          const SizedBox(height: 16),

          // قسم البيانات / Data Section
          _buildSection(
            title: 'البيانات',
            titleEn: 'Data',
            icon: Icons.storage_rounded,
            children: [
              _buildActionTile(
                title: 'تصدير البيانات',
                subtitle: 'تصدير جميع العناصر كـ JSON',
                icon: Icons.upload_rounded,
                onTap: _exportData,
              ),
              _buildActionTile(
                title: 'استيراد البيانات',
                subtitle: 'استيراد عناصر من ملف JSON',
                icon: Icons.download_rounded,
                onTap: _importData,
              ),
              _buildActionTile(
                title: 'تفريغ سلة المحذوفات',
                subtitle: 'حذف العناصر المحذوفة نهائياً',
                icon: Icons.delete_outline_rounded,
                onTap: _emptyTrash,
              ),
              _buildActionTile(
                title: 'مسح جميع البيانات',
                subtitle: 'تحذير: لا يمكن التراجع!',
                icon: Icons.delete_forever_rounded,
                color: AppColors.error,
                onTap: _showClearDataDialog,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم حول التطبيق / About Section
          _buildSection(
            title: 'حول التطبيق',
            titleEn: 'About',
            icon: Icons.info_outline_rounded,
            children: [
              _buildInfoTile(
                title: 'الإصدار',
                value: '1.0.0',
              ),
              _buildInfoTile(
                title: 'المطور',
                value: 'NexusClip Team',
              ),
              _buildActionTile(
                title: 'GitHub',
                subtitle: 'المستودع المصدري',
                icon: Icons.code_rounded,
                onTap: () {
                  // فتح رابط GitHub
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String titleEn,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    titleEn,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: isEnabled
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'تفعيل',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.textTertiary.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Slider(
          value: value,
          min: 0.1,
          max: 0.9,
          divisions: 8,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: AppColors.cardBackground,
        style: const TextStyle(color: AppColors.textPrimary),
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text('$item'),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        icon,
        color: color ?? AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.8),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _syncService.isRunning
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                color: _syncService.isRunning
                    ? AppColors.success
                    : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _syncService.isRunning ? 'متصل' : 'غير متصل',
                style: TextStyle(
                  color: _syncService.isRunning
                      ? AppColors.success
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_syncService.discoveredDevices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'الأجهزة المكتشفة: ${_syncService.discoveredDevices.length}',
              style: TextStyle(
                color: AppColors.textTertiary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatRow('إجمالي العناصر', _statistics['total'] ?? 0),
          _buildStatRow('نصوص', _statistics['text'] ?? 0),
          _buildStatRow('أكواد', _statistics['code'] ?? 0),
          _buildStatRow('روابط', _statistics['links'] ?? 0),
          _buildStatRow('كلمات مرور', _statistics['passwords'] ?? 0),
          _buildStatRow('قوالب', _statistics['templates'] ?? 0),
          _buildStatRow('مثبتة', _statistics['pinned'] ?? 0),
          _buildStatRow('محذوفة', _statistics['deleted'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showRegenerateKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'إعادة إنشاء مفتاح التشفير',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'تحذير: سيتم فقدان جميع البيانات المشفرة (كلمات المرور)!\n\nهل أنت متأكد؟',
          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _encryptionService.regenerateKey();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إعادة إنشاء مفتاح التشفير'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'مسح جميع البيانات',
          style: TextStyle(color: AppColors.error),
        ),
        content: Text(
          'تحذير: سيتم حذف جميع العناصر نهائياً!\n\nهذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _databaseService.clearAllData();
              _loadStatistics();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم مسح جميع البيانات'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('مسح الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final data = _databaseService.exportData();
      // يمكن حفظ البيانات لملف أو مشاركتها
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير ${data.length} عنصر'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التصدير: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    // يمكن تنفيذ اختيار ملف واستيراده
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الاستيراد قيد التطوير'),
          backgroundColor: AppColors.cardBackground,
        ),
      );
    }
  }

  Future<void> _emptyTrash() async {
    try {
      await _databaseService.emptyTrash();
      _loadStatistics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفريغ سلة المحذوفات'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تفريغ السلة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}


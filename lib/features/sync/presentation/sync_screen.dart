import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/sync_service.dart';
import '../../vault/widgets/glassmorphic_container.dart';

/// NexusClip - شاشة المزامنة
/// Sync Screen
///
/// واجهة للتحكم في مزامنة الحافظة مع Linux
/// Interface for clipboard sync with Linux
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SyncService _syncService = SyncService();
  
  bool _isLoading = false;
  String? _localIp;
  String _lastActivity = '';

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _loadLocalIp();
  }

  void _setupCallbacks() {
    _syncService.onClipboardReceived = (content) {
      if (mounted) {
        setState(() {
          _lastActivity = 'تم استلام: ${_truncate(content, 30)}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم استلام محتوى من جهاز آخر',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    };

    _syncService.onDeviceDiscovered = (device) {
      if (mounted) {
        setState(() {
          _lastActivity = 'تم اكتشاف: ${device.name}';
        });
      }
    };

    _syncService.onDeviceDisconnected = (device) {
      if (mounted) {
        setState(() {
          _lastActivity = 'انقطع الاتصال: ${device.name}';
        });
      }
    };

    _syncService.onError = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $message'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    };
  }

  Future<void> _loadLocalIp() async {
    final ip = await _syncService.getLocalIpAddress();
    if (mounted) {
      setState(() {
        _localIp = ip;
      });
    }
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _toggleSync() async {
    setState(() => _isLoading = true);

    try {
      if (_syncService.isRunning) {
        await _syncService.stop();
      } else {
        await _syncService.start();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync toggle error: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _discoverDevices() async {
    setState(() => _isLoading = true);

    try {
      await _syncService.discoverDevices();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Discovery error: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
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
          'المزامنة',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _discoverDevices,
            tooltip: 'بحث عن أجهزة',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // حالة المزامنة / Sync Status
          _buildStatusCard(),

          const SizedBox(height: 16),

          // معلومات الشبكة / Network Info
          _buildNetworkInfoCard(),

          const SizedBox(height: 16),

          // الأجهزة المكتشفة / Discovered Devices
          _buildDevicesCard(),

          const SizedBox(height: 16),

          // تعليمات Linux / Linux Instructions
          _buildInstructionsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isRunning = _syncService.isRunning;
    final isConnected = _syncService.isConnected;

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      borderColor: isRunning
          ? AppColors.success.withValues(alpha: 0.5)
          : AppColors.border.withValues(alpha: 0.3),
      child: Column(
        children: [
          // أيقونة الحالة / Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (isRunning ? AppColors.success : AppColors.textTertiary)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRunning ? Icons.sync_rounded : Icons.sync_disabled_rounded,
              size: 40,
              color: isRunning ? AppColors.success : AppColors.textTertiary,
            ),
          ),

          const SizedBox(height: 16),

          // نص الحالة / Status Text
          Text(
            isRunning ? 'المزامنة نشطة' : 'المزامنة متوقفة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isRunning ? AppColors.success : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            isConnected
                ? 'متصل بـ ${_syncService.connectedDevice?.name ?? "جهاز"}'
                : isRunning
                    ? 'جاري البحث عن أجهزة...'
                    : 'اضغط لبدء المزامنة',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),

          if (_lastActivity.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _lastActivity,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary.withValues(alpha: 0.7),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // زر التشغيل/الإيقاف / Toggle Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleSync,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  : Icon(
                      isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    ),
              label: Text(
                isRunning ? 'إيقاف المزامنة' : 'بدء المزامنة',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkInfoCard() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'معلومات الشبكة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('عنوان IP المحلي', _localIp ?? 'غير متاح'),
          _buildInfoRow('المنفذ', '4040'),
          _buildInfoRow('البروتوكول', 'UDP'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesCard() {
    final devices = _syncService.discoveredDevices;

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.devices_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'الأجهزة المكتشفة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${devices.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لم يتم اكتشاف أي أجهزة',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تأكد من تشغيل السكريبت على Linux',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...devices.map((device) => _buildDeviceTile(device)),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(SyncDevice device) {
    final isConnected = _syncService.connectedDevice?.address == device.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getPlatformColor(device.platform).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getPlatformIcon(device.platform),
              color: _getPlatformColor(device.platform),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'متصل',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.platform} • ${device.address}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ],
            ),
          ),
          if (!isConnected)
            IconButton(
              icon: const Icon(
                Icons.link_rounded,
                color: AppColors.primary,
              ),
              onPressed: () => _connectToDevice(device),
              tooltip: 'اتصال',
            )
          else
            IconButton(
              icon: const Icon(
                Icons.link_off_rounded,
                color: AppColors.error,
              ),
              onPressed: () => _syncService.disconnect(),
              tooltip: 'قطع الاتصال',
            ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'linux':
        return Icons.computer_rounded;
      case 'android':
        return Icons.phone_android_rounded;
      case 'windows':
        return Icons.laptop_windows_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'linux':
        return AppColors.categoryCode;
      case 'android':
        return AppColors.categoryLive;
      case 'windows':
        return AppColors.categoryLinks;
      case 'macos':
        return AppColors.textPrimary;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _connectToDevice(SyncDevice device) async {
    final success = await _syncService.connectToDevice(device);
    if (mounted) {
      if (success) {
        setState(() {
          _lastActivity = 'متصل بـ ${device.name}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الاتصال بـ ${device.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الاتصال'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildInstructionsCard() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              const Text(
                'تعليمات المزامنة مع Linux',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '1',
            'تثبيت المتطلبات',
            'pip install pyperclip zeroconf',
          ),
          _buildInstructionStep(
            '2',
            'تشغيل السكريبت',
            'python3 nexusclip_daemon.py',
          ),
          _buildInstructionStep(
            '3',
            'التأكد من الشبكة',
            'يجب أن يكون الجهازان على نفس الشبكة المحلية',
          ),
          _buildInstructionStep(
            '4',
            'فتح المنفذ',
            'تأكد من فتح Port 4040 في جدار الحماية',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontFamily: title.contains('تثبيت') || title.contains('تشغيل')
                          ? 'JetBrainsMono'
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


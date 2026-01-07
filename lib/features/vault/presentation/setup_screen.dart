import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/platform_service.dart';

/// NexusClip - شاشة الإعداد
/// Setup Screen
///
/// تظهر عند أول تشغيل لطلب الصلاحيات اللازمة
/// Shown on first launch to request necessary permissions
class SetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const SetupScreen({
    super.key,
    required this.onSetupComplete,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PlatformService _platformService = PlatformService();
  
  // ignore: unused_field
  final int _currentStep = 0;
  bool _overlayPermissionGranted = false;
  bool _accessibilityPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final permissions = await _platformService.checkAllPermissions();
    setState(() {
      _overlayPermissionGranted = permissions['overlay'] ?? false;
      _accessibilityPermissionGranted = permissions['accessibility'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // الشعار والعنوان / Logo and Title
              _buildHeader(),
              
              const SizedBox(height: 48),
              
              // خطوات الإعداد / Setup Steps
              Expanded(
                child: _buildSetupSteps(),
              ),
              
              // زر المتابعة / Continue Button
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // أيقونة التطبيق / App Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.content_paste_rounded,
            size: 50,
            color: AppColors.background,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // اسم التطبيق / App Name
        const Text(
          'NexusClip',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // الوصف / Description
        Text(
          'نظام الحافظة الذكي\nSmart Clipboard Management',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSetupSteps() {
    return ListView(
      children: [
        // الخطوة 1: صلاحية العرض فوق التطبيقات
        // Step 1: Overlay Permission
        _buildPermissionStep(
          stepNumber: 1,
          title: 'العرض فوق التطبيقات',
          titleEn: 'Display Over Apps',
          description: 'لعرض المقبض الجانبي والشريط السريع',
          descriptionEn: 'To show side handle and quick panel',
          icon: Icons.layers_rounded,
          isGranted: _overlayPermissionGranted,
          onRequest: () async {
            await _platformService.requestOverlayPermission();
            await Future.delayed(const Duration(seconds: 1));
            await _checkCurrentPermissions();
          },
        ),
        
        const SizedBox(height: 16),
        
        // الخطوة 2: صلاحية خدمة الوصول
        // Step 2: Accessibility Permission
        _buildPermissionStep(
          stepNumber: 2,
          title: 'خدمة الوصول',
          titleEn: 'Accessibility Service',
          description: 'لمراقبة الحافظة والتحكم بالمؤشر',
          descriptionEn: 'To monitor clipboard and control cursor',
          icon: Icons.accessibility_new_rounded,
          isGranted: _accessibilityPermissionGranted,
          onRequest: () async {
            await _platformService.requestAccessibilityPermission();
            await Future.delayed(const Duration(seconds: 1));
            await _checkCurrentPermissions();
          },
        ),
        
        const SizedBox(height: 32),
        
        // ملاحظات الخصوصية / Privacy Notes
        _buildPrivacyNotes(),
      ],
    );
  }

  Widget _buildPermissionStep({
    required int stepNumber,
    required String title,
    required String titleEn,
    required String description,
    required String descriptionEn,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted 
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // رقم الخطوة / Step Number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isGranted ? AppColors.success : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isGranted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '$stepNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // الأيقونة / Icon
              Icon(
                icon,
                color: isGranted ? AppColors.success : AppColors.primary,
                size: 28,
              ),
              
              const SizedBox(width: 12),
              
              // العناوين / Titles
              Expanded(
                child: Column(
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
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // الوصف / Description
          Text(
            '$description\n$descriptionEn',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // زر الصلاحية / Permission Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isGranted ? null : onRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: isGranted ? AppColors.success : AppColors.primary,
                disabledBackgroundColor: AppColors.success.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isGranted ? Icons.check_circle : Icons.settings,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGranted ? 'تم التفعيل ✓' : 'تفعيل الصلاحية',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'الخصوصية والأمان',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• جميع بياناتك مُخزنة محلياً فقط\n'
            '• لا يتم إرسال أي بيانات للإنترنت\n'
            '• كلمات المرور مُشفرة بـ AES-256\n'
            '• المزامنة تتم عبر الشبكة المحلية فقط',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final canContinue = _overlayPermissionGranted;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canContinue ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  canContinue ? 'ابدأ الآن' : 'أكمل الإعدادات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canContinue ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: canContinue ? Colors.white : Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    // بدء الخدمة / Start service
    await _platformService.startService();
    
    // إشعار الانتهاء / Notify completion
    widget.onSetupComplete();
  }
}

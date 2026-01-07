import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/clip_item.dart';
import 'glassmorphic_container.dart';

/// NexusClip - بطاقة عنصر الحافظة
/// Clipboard Item Card
///
/// تعرض عنصر واحد من سجل الحافظة مع تأثيرات Glassmorphism
/// Displays a single clipboard item with Glassmorphism effects
class ClipItemCard extends StatelessWidget {
  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final bool showSecure;

  const ClipItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.onPin,
    required this.onDelete,
    this.showSecure = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: GlassmorphicContainer(
        padding: EdgeInsets.zero,
        borderColor: _getBorderColor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الهيدر / Header
            _buildHeader(),
            
            // المحتوى / Content
            _buildContent(),
            
            // الفوتر / Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (item.isPinned) {
      return AppColors.accent.withValues(alpha: 0.5);
    }
    return AppColors.getCategoryColor(item.type).withValues(alpha: 0.3);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // أيقونة النوع / Type Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.getCategoryColor(item.type).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _getTypeIcon(),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // معلومات العنصر / Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // التصنيف / Category
                    Text(
                      _getTypeLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getCategoryColor(item.type),
                      ),
                    ),
                    
                    // لغة البرمجة (للأكواد)
                    if (item.subType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.categoryCode.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.subType!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.categoryCode,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(item.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // شارات الحالة / Status Badges
          if (item.isPinned)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.push_pin,
                size: 16,
                color: AppColors.accent,
              ),
            ),
          
          if (item.isSecure)
            Icon(
              Icons.lock,
              size: 16,
              color: AppColors.categorySecure,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final displayText = showSecure && item.isSecure
        ? item.displayContent
        : item.content;

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(
        minHeight: 60,
        maxHeight: 150,
      ),
      child: item.type == 'code'
          ? _buildCodeContent(displayText)
          : _buildTextContent(displayText),
    );
  }

  Widget _buildTextContent(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCodeContent(String code) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.categoryCode.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'JetBrainsMono',
            color: Color(0xFFE6EDF3),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // عداد الاستخدام / Usage Count
          if (item.usageCount > 0) ...[
            Icon(
              Icons.copy,
              size: 12,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              '${item.usageCount}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // طول المحتوى / Content Length
          Icon(
            Icons.text_fields,
            size: 12,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '${item.content.length}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
          
          const Spacer(),
          
          // أزرار الإجراءات السريعة / Quick Actions
          _buildQuickAction(
            icon: Icons.copy,
            onTap: onTap,
            tooltip: 'نسخ',
          ),
          const SizedBox(width: 8),
          _buildQuickAction(
            icon: item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            onTap: onPin,
            tooltip: item.isPinned ? 'إلغاء التثبيت' : 'تثبيت',
            color: item.isPinned ? AppColors.accent : null,
          ),
          const SizedBox(width: 8),
          _buildQuickAction(
            icon: Icons.delete_outline,
            onTap: onDelete,
            tooltip: 'حذف',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: color ?? AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon() {
    IconData icon;
    
    switch (item.type) {
      case 'link':
        icon = Icons.link_rounded;
        break;
      case 'code':
        icon = Icons.code_rounded;
        break;
      case 'password':
        icon = Icons.lock_rounded;
        break;
      case 'email':
        icon = Icons.email_rounded;
        break;
      case 'phone':
        icon = Icons.phone_rounded;
        break;
      case 'template':
        icon = Icons.text_snippet_rounded;
        break;
      default:
        icon = Icons.content_paste_rounded;
    }
    
    return Icon(
      icon,
      size: 18,
      color: AppColors.getCategoryColor(item.type),
    );
  }

  String _getTypeLabel() {
    switch (item.type) {
      case 'link':
        return 'رابط';
      case 'code':
        return 'كود';
      case 'password':
        return 'كلمة مرور';
      case 'email':
        return 'بريد';
      case 'phone':
        return 'رقم هاتف';
      case 'template':
        return 'قالب';
      default:
        return 'نص';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

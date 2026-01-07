import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// بيانات تبويب الفئة
/// Category Tab Data
class CategoryTabData {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const CategoryTabData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// NexusClip - تبويب الفئة
/// Category Tab Widget
///
/// تبويب مخصص لعرض فئة من فئات الحافظة
/// Custom tab for displaying clipboard categories
class CategoryTab extends StatelessWidget {
  final CategoryTabData data;
  final bool isSelected;

  const CategoryTab({
    super.key,
    required this.data,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? data.color.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: data.color.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.icon,
              size: 18,
              color: isSelected ? data.color : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? data.color : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة العدد
/// Count Badge
class CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const CountBadge({
    super.key,
    required this.count,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

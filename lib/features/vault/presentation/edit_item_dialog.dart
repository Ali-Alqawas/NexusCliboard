import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/clip_item.dart';
import '../../../core/services/database_service.dart';
import '../widgets/glassmorphic_container.dart';

/// NexusClip - حوار تعديل العنصر
/// Edit Item Dialog
///
/// يتيح تعديل محتوى وخصائص عنصر الحافظة
/// Allows editing clipboard item content and properties
class EditItemDialog extends StatefulWidget {
  final ClipItem item;
  final VoidCallback? onSaved;

  const EditItemDialog({
    super.key,
    required this.item,
    this.onSaved,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final DatabaseService _databaseService = DatabaseService();
  late TextEditingController _contentController;
  late TextEditingController _labelController;
  late String _selectedType;
  late bool _isPinned;
  late bool _isSecure;

  final List<Map<String, dynamic>> _types = [
    {'id': 'text', 'label': 'نص', 'icon': Icons.text_fields_rounded},
    {'id': 'code', 'label': 'كود', 'icon': Icons.code_rounded},
    {'id': 'link', 'label': 'رابط', 'icon': Icons.link_rounded},
    {'id': 'email', 'label': 'بريد', 'icon': Icons.email_rounded},
    {'id': 'phone', 'label': 'هاتف', 'icon': Icons.phone_rounded},
    {'id': 'password', 'label': 'كلمة مرور', 'icon': Icons.lock_rounded},
    {'id': 'template', 'label': 'قالب', 'icon': Icons.text_snippet_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.item.content);
    _labelController = TextEditingController(text: widget.item.label ?? '');
    _selectedType = widget.item.type;
    _isPinned = widget.item.isPinned;
    _isSecure = widget.item.isSecure;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المحتوى لا يمكن أن يكون فارغاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // تحديث العنصر / Update item
      widget.item.content = _contentController.text;
      widget.item.label = _labelController.text.isEmpty ? null : _labelController.text;
      widget.item.isPinned = _isPinned;
      widget.item.isSecure = _isSecure;
      widget.item.lastUsedAt = DateTime.now();

      // حفظ في قاعدة البيانات / Save to database
      await _databaseService.updateItem(widget.item);

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم حفظ التعديلات'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassmorphicContainer(
        borderRadius: 20,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر / Header
              _buildHeader(),

              // المحتوى / Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // حقل المحتوى / Content Field
                      _buildContentField(),

                      const SizedBox(height: 16),

                      // حقل التسمية (للقوالب) / Label Field (for templates)
                      _buildLabelField(),

                      const SizedBox(height: 16),

                      // اختيار النوع / Type Selection
                      _buildTypeSelector(),

                      const SizedBox(height: 16),

                      // الخيارات / Options
                      _buildOptions(),
                    ],
                  ),
                ),
              ),

              // الأزرار / Buttons
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل العنصر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Edit Item',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المحتوى',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: 6,
          minLines: 3,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: _selectedType == 'code' ? 'JetBrainsMono' : null,
          ),
          decoration: InputDecoration(
            hintText: 'أدخل المحتوى هنا...',
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'التسمية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(اختياري)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _labelController,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'تسمية للعنصر (مثال: قالب الترحيب)',
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'النوع',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _types.map((type) {
            final isSelected = _selectedType == type['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type['id'];
                  if (type['id'] == 'password') {
                    _isSecure = true;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.getCategoryColor(type['id']).withValues(alpha: 0.2)
                      : AppColors.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.getCategoryColor(type['id'])
                        : AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'],
                      size: 16,
                      color: isSelected
                          ? AppColors.getCategoryColor(type['id'])
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type['label'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.getCategoryColor(type['id'])
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الخيارات',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildOptionTile(
                icon: Icons.push_pin_rounded,
                title: 'تثبيت العنصر',
                subtitle: 'إبقاء العنصر في الأعلى',
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildOptionTile(
                icon: Icons.lock_rounded,
                title: 'عنصر آمن',
                subtitle: 'إخفاء المحتوى وتشفيره',
                value: _isSecure,
                onChanged: (value) => setState(() => _isSecure = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: value ? AppColors.primary : AppColors.textTertiary,
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textTertiary.withValues(alpha: 0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('إلغاء'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('حفظ التعديلات'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// وظيفة مساعدة لعرض حوار التعديل
/// Helper function to show edit dialog
Future<bool?> showEditItemDialog(BuildContext context, ClipItem item, {VoidCallback? onSaved}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => EditItemDialog(
      item: item,
      onSaved: onSaved,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/clip_item.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/platform_service.dart';
import '../widgets/clip_item_card.dart';
import '../widgets/category_tab.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/virtual_dpad.dart';
import '../widgets/glassmorphic_container.dart';

/// NexusClip - شاشة الخزنة الرئيسية
/// Main Vault Screen
///
/// تحتوي على 5 تبويبات:
/// Contains 5 tabs:
/// 1. Live Stream - آخر العناصر المنسوخة
/// 2. Code Snippets - مقاطع الأكواد
/// 3. Secure Vault - الخزنة الآمنة
/// 4. Templates - القوالب الجاهزة
/// 5. Links - الروابط
class VaultScreen extends StatefulWidget {
  final bool isOverlay;

  const VaultScreen({
    super.key,
    this.isOverlay = false,
  });

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  final PlatformService _platformService = PlatformService();
  
  List<ClipItem> _allItems = [];
  List<ClipItem> _filteredItems = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showDPad = false;

  // فئات التبويبات / Tab Categories
  final List<CategoryTabData> _categories = [
    CategoryTabData(
      id: 'live',
      label: 'Live',
      icon: Icons.stream_rounded,
      color: AppColors.categoryLive,
    ),
    CategoryTabData(
      id: 'code',
      label: 'Code',
      icon: Icons.code_rounded,
      color: AppColors.categoryCode,
    ),
    CategoryTabData(
      id: 'secure',
      label: 'Secure',
      icon: Icons.lock_rounded,
      color: AppColors.categorySecure,
    ),
    CategoryTabData(
      id: 'template',
      label: 'Templates',
      icon: Icons.text_snippet_rounded,
      color: AppColors.categoryTemplates,
    ),
    CategoryTabData(
      id: 'link',
      label: 'Links',
      icon: Icons.link_rounded,
      color: AppColors.categoryLinks,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _filterItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    try {
      _allItems = _databaseService.getAllItems();
      _filterItems();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    final currentCategory = _categories[_tabController.index].id;
    
    setState(() {
      if (currentCategory == 'live') {
        // Live Stream - جميع العناصر مرتبة زمنياً
        _filteredItems = _allItems
            .where((item) => 
                _searchQuery.isEmpty ||
                item.content.toLowerCase().contains(_searchQuery.toLowerCase()))
            .take(50)
            .toList();
      } else if (currentCategory == 'secure') {
        // Secure Vault - كلمات المرور
        _filteredItems = _allItems
            .where((item) => 
                (item.type == 'password' || item.isSecure) &&
                (_searchQuery.isEmpty ||
                 item.content.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();
      } else {
        // باقي الفئات
        _filteredItems = _allItems
            .where((item) => 
                item.type == currentCategory &&
                (_searchQuery.isEmpty ||
                 item.content.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();
      }
    });
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _filterItems();
  }

  Future<void> _onItemTap(ClipItem item) async {
    // نسخ للحافظة / Copy to clipboard
    await Clipboard.setData(ClipboardData(text: item.content));
    
    // تحديث عداد الاستخدام / Update usage count
    item.markAsUsed();
    
    // عرض رسالة / Show message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('تم النسخ للحافظة'),
            ],
          ),
          backgroundColor: AppColors.cardBackground,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // إغلاق الـ Overlay إذا كان مفتوحاً
    if (widget.isOverlay && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onItemLongPress(ClipItem item) async {
    // عرض قائمة الخيارات / Show options menu
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionsSheet(item),
    );
  }

  Future<void> _onItemPin(ClipItem item) async {
    item.togglePin();
    _loadItems();
  }

  Future<void> _onItemDelete(ClipItem item) async {
    item.softDelete();
    _loadItems();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حذف العنصر'),
          backgroundColor: AppColors.cardBackground,
          action: SnackBarAction(
            label: 'تراجع',
            textColor: AppColors.primary,
            onPressed: () {
              item.restore();
              _loadItems();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isOverlay 
          ? Colors.transparent 
          : AppColors.background,
      body: widget.isOverlay 
          ? _buildOverlayBody() 
          : _buildFullBody(),
    );
  }

  Widget _buildOverlayBody() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {}, // منع انتشار النقر
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullBody() {
    return SafeArea(
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // الهيدر / Header
        _buildHeader(),
        
        // شريط البحث / Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SearchBarWidget(
            onSearch: _onSearch,
            hintText: 'ابحث في الحافظة...',
          ),
        ),
        
        // التبويبات / Tabs
        _buildTabBar(),
        
        // المحتوى / Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTabContent(),
        ),
        
        // Virtual D-Pad (اختياري)
        if (_showDPad) _buildDPad(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // أيقونة وعنوان / Icon and Title
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.content_paste_rounded,
              color: AppColors.background,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NexusClip',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_allItems.length} عنصر محفوظ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // أزرار الإجراءات / Action Buttons
          IconButton(
            icon: Icon(
              _showDPad ? Icons.gamepad : Icons.gamepad_outlined,
              color: _showDPad ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _showDPad = !_showDPad),
            tooltip: 'Virtual D-Pad',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
            onPressed: _openSettings,
            tooltip: 'الإعدادات',
          ),
          
          // زر الإغلاق (للـ Overlay فقط)
          if (widget.isOverlay)
            IconButton(
              icon: const Icon(Icons.close),
              color: AppColors.textSecondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: _categories[_tabController.index].color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: _categories.map((category) {
          return CategoryTab(
            data: category,
            isSelected: _categories.indexOf(category) == _tabController.index,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipItemCard(
              item: item,
              onTap: () => _onItemTap(item),
              onLongPress: () => _onItemLongPress(item),
              onPin: () => _onItemPin(item),
              onDelete: () => _onItemDelete(item),
              showSecure: _categories[_tabController.index].id == 'secure',
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final category = _categories[_tabController.index];
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category.icon,
            size: 64,
            color: category.color.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد عناصر في ${category.label}',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب البحث بكلمات أخرى'
                : 'سيظهر المحتوى المنسوخ هنا تلقائياً',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPad() {
    return GlassmorphicContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: VirtualDPad(
        onDirectionPressed: (direction) async {
          await _platformService.moveCursor(direction);
          // اهتزاز خفيف / Light haptic
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildOptionsSheet(ClipItem item) {
    return GlassmorphicContainer(
      margin: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب / Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // معاينة المحتوى / Content preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.shortDescription,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const Divider(color: AppColors.border),
          
          // الخيارات / Options
          ListTile(
            leading: const Icon(Icons.copy, color: AppColors.primary),
            title: const Text('نسخ', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              _onItemTap(item);
            },
          ),
          ListTile(
            leading: Icon(
              item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: item.isPinned ? AppColors.accent : AppColors.textSecondary,
            ),
            title: Text(
              item.isPinned ? 'إلغاء التثبيت' : 'تثبيت',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              _onItemPin(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.textSecondary),
            title: const Text('تعديل', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              _editItem(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('حذف', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              _onItemDelete(item);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _openSettings() {
    // TODO: فتح شاشة الإعدادات
  }

  void _editItem(ClipItem item) {
    // TODO: فتح محرر العنصر
  }
}

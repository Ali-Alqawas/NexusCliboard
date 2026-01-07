import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// NexusClip - شريط البحث
/// Search Bar Widget
///
/// شريط بحث بتصميم Glassmorphism
/// Search bar with Glassmorphism design
class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final String hintText;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.hintText = 'ابحث...',
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onSearch(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // أيقونة البحث / Search Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
          
          // حقل الإدخال / Input Field
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSearch,
            ),
          ),
          
          // زر المسح / Clear Button
          if (_hasText)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.textTertiary.withValues(alpha: 0.7),
                size: 20,
              ),
              onPressed: _clearSearch,
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}

/// شريط بحث متقدم مع فلاتر
/// Advanced Search Bar with Filters
class AdvancedSearchBar extends StatefulWidget {
  final Function(String, SearchFilters) onSearch;
  final String hintText;

  const AdvancedSearchBar({
    super.key,
    required this.onSearch,
    this.hintText = 'ابحث...',
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _showFilters = false;
  SearchFilters _filters = const SearchFilters();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    widget.onSearch(query, _filters);
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
  }

  void _updateFilters(SearchFilters filters) {
    setState(() => _filters = filters);
    _onSearch(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث الرئيسي / Main Search Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiary.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
              
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: _onSearch,
                ),
              ),
              
              // زر الفلاتر / Filters Button
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.tune : Icons.tune_outlined,
                  color: _showFilters 
                      ? AppColors.primary 
                      : AppColors.textTertiary.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: _toggleFilters,
                splashRadius: 20,
              ),
            ],
          ),
        ),
        
        // لوحة الفلاتر / Filters Panel
        if (_showFilters) _buildFiltersPanel(),
      ],
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فلترة النتائج',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // خيارات الفلترة / Filter Options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'المثبتة فقط',
                isSelected: _filters.pinnedOnly,
                onTap: () => _updateFilters(
                  _filters.copyWith(pinnedOnly: !_filters.pinnedOnly),
                ),
              ),
              _buildFilterChip(
                label: 'اليوم',
                isSelected: _filters.todayOnly,
                onTap: () => _updateFilters(
                  _filters.copyWith(todayOnly: !_filters.todayOnly),
                ),
              ),
              _buildFilterChip(
                label: 'الأكثر استخداماً',
                isSelected: _filters.sortByUsage,
                onTap: () => _updateFilters(
                  _filters.copyWith(sortByUsage: !_filters.sortByUsage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// فلاتر البحث
/// Search Filters
class SearchFilters {
  final bool pinnedOnly;
  final bool todayOnly;
  final bool sortByUsage;
  final List<String>? types;

  const SearchFilters({
    this.pinnedOnly = false,
    this.todayOnly = false,
    this.sortByUsage = false,
    this.types,
  });

  SearchFilters copyWith({
    bool? pinnedOnly,
    bool? todayOnly,
    bool? sortByUsage,
    List<String>? types,
  }) {
    return SearchFilters(
      pinnedOnly: pinnedOnly ?? this.pinnedOnly,
      todayOnly: todayOnly ?? this.todayOnly,
      sortByUsage: sortByUsage ?? this.sortByUsage,
      types: types ?? this.types,
    );
  }
}

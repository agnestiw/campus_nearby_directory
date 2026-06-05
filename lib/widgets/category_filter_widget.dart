import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/category_model.dart';

class CategoryFilterWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Semua"
          _buildChip(
            label: 'Semua',
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
            baseColor: const Color(0xFF1A6FDB),
          ),
          const SizedBox(width: 8),

          // Chip per kategori
          ...categories.map((cat) {
            final icon = AppTheme.getCategoryIcon(cat.name);
            final isSelected = selectedCategoryId == cat.id;
            final catColor = AppTheme.getCategoryColor(cat.name);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: cat.name,
                icon: icon,
                isSelected: isSelected,
                onTap: () => onCategorySelected(cat.id),
                baseColor: catColor,
              ),
            );
          }),

          // "Lainnya" chip
          _buildChip(
            label: 'Lainnya',
            icon: Icons.more_horiz_rounded,
            isSelected: false,
            onTap: () {},
            baseColor: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color baseColor,
  }) {
    final bgColor = isSelected ? baseColor : baseColor.withOpacity(0.1);
    final textColor = isSelected ? Colors.white : baseColor;
    final borderColor = isSelected ? baseColor : baseColor.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Text(
              _capitalize(label),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
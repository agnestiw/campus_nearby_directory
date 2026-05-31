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
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Semua"
          _buildChip(
            label: 'Semua',
            icon: Icons.apps_rounded,
            color: AppTheme.primary,
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          ),

          const SizedBox(width: 8),

          // Chip per kategori
          ...categories.map((cat) {
            final color = AppTheme.getCategoryColor(cat.name);
            final icon = AppTheme.getCategoryIcon(cat.name);
            final isSelected = selectedCategoryId == cat.id;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: cat.name,
                icon: icon,
                color: color,
                isSelected: isSelected,
                onTap: () => onCategorySelected(cat.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 5),
            Text(
              _capitalize(label),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
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
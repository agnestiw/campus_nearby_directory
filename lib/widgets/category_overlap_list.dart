import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';

class CategoryOverlapList extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategorySelected;

  const CategoryOverlapList({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  // Exact colors from the user's reference image
  static const List<Color> _cardColors = [
    Color(0xFFE6DDFB), // Soft Light Purple
    Color(0xFFF7F8CC), // Soft Lime / Yellow-Green
    Color(0xFFD6E2FB), // Soft Light Blue
    Color(0xFFFBE4D6), // Soft Peach / Orange
    Color(0xFFF8D8E6), // Soft Pink
    Color(0xFFE1F5E6), // Soft Mint
  ];

  static const List<String> _percentages = ['23%', '78%', '98%', '100%', '92%', '45%'];
  static const List<List<String>> _pills = [
    ['Terpopuler', '48 tempat'],
    ['Menengah', '26 tempat'],
    ['Dasar', '167 tempat'],
    ['Terdekat', '96 tempat'],
    ['Baru', '32 tempat'],
    ['Pilihan', '12 tempat'],
  ];

  Color _getTextColor(Color bgColor) {
    return const Color(0xFF1A1A2E); // Always dark text for soft pastel backgrounds
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    const double cardHeight = 160.0;
    const double overlapOffset = 135.0;
    final double totalHeight = cardHeight + ((categories.length - 1) * overlapOffset);

    return SizedBox(
      height: totalHeight + 40, // extra padding at bottom
      child: Stack(
        children: List.generate(categories.length, (index) {
          final category = categories[index];
          final bgColor = _cardColors[index % _cardColors.length];
          final textColor = _getTextColor(bgColor);
          final percentage = _percentages[index % _percentages.length];
          
          final pillText1 = _pills[index % _pills.length][0];
          final pillText2 = '${category.placeCount} tempat';
          final pillTexts = [pillText1, pillText2];

          return Positioned(
            top: index * overlapOffset,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: Container(
                height: cardHeight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(32),
                  // Removed drop shadow to make it flat and exact like the image
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name[0].toUpperCase() + category.name.substring(1),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: pillTexts.map((text) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: textColor.withOpacity(0.4),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: textColor.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          percentage,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2E), // Dark gray/black circle
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

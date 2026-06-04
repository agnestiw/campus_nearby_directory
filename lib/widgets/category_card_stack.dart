import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/category_model.dart';

class CategoryCardStack extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategorySelected;

  const CategoryCardStack({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<CategoryCardStack> createState() => _CategoryCardStackState();
}

class _CategoryCardStackState extends State<CategoryCardStack> {
  late List<CategoryModel> _cards;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.categories);
  }

  @override
  void didUpdateWidget(covariant CategoryCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      _cards = List.from(widget.categories);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragOffset.distance > 100 || details.velocity.pixelsPerSecond.distance > 800) {
      // Swiped away
      setState(() {
        final removed = _cards.removeAt(0);
        _cards.add(removed);
        _dragOffset = Offset.zero;
      });
    } else {
      // Reset
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List.generate(_cards.length, (index) {
            // Display only top 4 cards
            if (index > 3) return const SizedBox.shrink();

            final actualCardIndex = _cards.length > 4 ? 3 - index : _cards.length - 1 - index;
            if (actualCardIndex >= _cards.length) return const SizedBox.shrink();

            final card = _cards[actualCardIndex];
            final isFront = actualCardIndex == 0;

            // Stack upwards like the image
            final scale = 1.0 - (actualCardIndex * 0.08);
            final verticalOffset = -(actualCardIndex * 35.0);

            final offset = isFront ? _dragOffset : Offset(0, verticalOffset);
            final angle = isFront ? (_dragOffset.dx / width) * (pi / 8) : 0.0;

            final baseColor = AppTheme.getCategoryColor(card.name);
            final icon = AppTheme.getCategoryIcon(card.name);

            // Background cards are darkened to match the provided design style
            final cardColor = isFront ? baseColor : const Color(0xFF2C2C2C);
            final textColor = isFront ? Colors.white : Colors.white54;

            Widget cardWidget = AnimatedContainer(
              duration: isFront && _dragOffset != Offset.zero
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..translate(offset.dx, offset.dy)
                ..rotateZ(angle)
                ..scale(scale),
              transformAlignment: Alignment.center,
              child: GestureDetector(
                onPanUpdate: isFront ? _onPanUpdate : null,
                onPanEnd: isFront ? _onPanEnd : null,
                onTap: () {
                  if (isFront) {
                    widget.onCategorySelected(card);
                  }
                },
                child: Container(
                  width: width * 0.85,
                  height: height * 0.7,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative circle
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFront ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isFront ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: textColor, size: 40),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kategori',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isFront ? Colors.white.withOpacity(0.8) : Colors.white38,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        card.name[0].toUpperCase() + card.name.substring(1),
                                        style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isFront)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Text(
                                          'Lihat Detail',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            return cardWidget;
          }),
        );
      },
    );
  }
}

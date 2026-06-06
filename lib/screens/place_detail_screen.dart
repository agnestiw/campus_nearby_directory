import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../models/place_model.dart';
import '../services/favorites_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;
  final String? categoryName;

  const PlaceDetailScreen({
    super.key,
    required this.place,
    this.categoryName,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final FavoritesService _favService = FavoritesService();

  // Design tokens matching categories_screen
  static const Color _primary   = Color(0xFF1A6FDB);
  static const Color _accent    = Color(0xFFD4FF59);
  static const Color _darkText  = Color(0xFF0B132B);
  static const Color _subtitle  = Color(0xFF64748B);
  static const Color _iconBg    = Color(0xFFE8EEFD);
  static const Color _cardBg    = Colors.white;
  static const Color _pageBg    = Color(0xFFFAFAFC);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    await _favService.loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final place        = widget.place;
    final categoryName = widget.categoryName;
    final catIcon      = AppTheme.getCategoryIcon(categoryName ?? '');

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          // ── Abstract background shapes (same as categories) ──
          Positioned(
            top: 260,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEFD),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 340,
            right: 0,
            child: CustomPaint(
              size: const Size(110, 140),
              painter: _CurvePainter(),
            ),
          ),

          // ── Main content ────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── App Bar dengan foto ──────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: _cardBg,
                foregroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _darkText,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.place.photoUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _iconBg,
                          child: Center(
                            child: Icon(catIcon, size: 60, color: _primary),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: _iconBg,
                          child: Center(
                            child: Icon(catIcon, size: 60, color: _primary),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                      // Favorite button
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ValueListenableBuilder<Set<int>>(
                              valueListenable: _favService.favorites,
                              builder: (context, favs, _) {
                                final isFav = favs.contains(widget.place.id);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    await _favService.toggleFavorite(widget.place.id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isFav
                                          ? const Color(0xFFEF4444)
                                          : _subtitle,
                                      size: 22,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Nama & Rating card ────────────────────
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge
                          if (categoryName != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _iconBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(catIcon,
                                      size: 13, color: _primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    categoryName,
                                    style: GoogleFonts.poppins(
                                      color: _primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Place name
                          Text(
                            place.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _darkText,
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Rating row
                          if (place.rating != null)
                            Row(
                              children: [
                                // Stars
                                ...List.generate(5, (i) {
                                  final filled = i < place.rating!.floor();
                                  final half = !filled &&
                                      i < place.rating! &&
                                      place.rating! - i >= 0.5;
                                  return Icon(
                                    half
                                        ? Icons.star_half_rounded
                                        : filled
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '${place.rating!.toStringAsFixed(1)} / 5.0',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _darkText,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Info tiles card ───────────────────────
                    _buildCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildInfoTile(
                            icon: Icons.location_on_outlined,
                            title: 'Alamat',
                            value: place.address,
                            isFirst: true,
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.access_time_outlined,
                            title: 'Jam Operasional',
                            value: place.openHour ?? 'Tidak tersedia',
                          ),
                          if (place.phone != null) ...[
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.phone_outlined,
                              title: 'Telepon',
                              value: place.phone!,
                            ),
                          ],
                          if (place.website != null) ...[
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.language_outlined,
                              title: 'Website',
                              value: place.website!,
                              isLast: true,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Deskripsi card ────────────────────────
                    if (place.description != null &&
                        place.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Deskripsi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _darkText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              place.description!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _subtitle,
                                height: 1.65,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Koordinat card ────────────────────────
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _iconBg, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _buildShaderIcon(Icons.my_location_outlined),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Koordinat',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _subtitle,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${place.latitude.toStringAsFixed(6)}, '
                                '${place.longitude.toStringAsFixed(6)}',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 12,
                                  color: _darkText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Tombol Buka Rute ─────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: _cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openRouteOnMap(context, place);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.directions_rounded, size: 20),
            label: Text(
              'Buka Rute ke Sini',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRouteOnMap(BuildContext context, PlaceModel place) {
    Navigator.pushNamed(context, '/map-route', arguments: place);
  }

  /// Reusable card container with same shadow/radius as categories
  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Info tile — white circle bg + border + lime-to-blue shader icon (same as categories)
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isFirst = false,
    bool isLast  = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // White circle with border + ShaderMask icon (matches category card)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8EEFD), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: _buildShaderIcon(icon),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _subtitle,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _darkText,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 82,
      endIndent: 20,
      color: Color(0xFFEFF3FB),
    );
  }

  /// Lime-to-blue two-tone shader icon — identical to categories_screen style
  Widget _buildShaderIcon(IconData icon) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4FF59), // lime
            Color(0xFFD4FF59),
            Color(0xFF1A6FDB), // blue
            Color(0xFF1A6FDB),
          ],
          stops: [0.0, 0.35, 0.35, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

/// Same curve painter as categories_screen.dart
class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4FF59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      const Offset(20, 20),
      8,
      paint..style = PaintingStyle.fill,
    );

    paint.style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(20, 20)
      ..quadraticBezierTo(size.width * 0.7, 10, size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
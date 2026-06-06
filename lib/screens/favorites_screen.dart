import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_logger.dart';
import '../models/place_model.dart';
import '../services/category_service.dart';
import '../services/favorites_service.dart';
import '../services/place_service.dart';
import '../widgets/place_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favService   = FavoritesService();
  final PlaceService     _placeService  = PlaceService();
  final CategoryService  _categoryService = CategoryService();

  // ── Search ───────────────────────────────────────────────────────────────
  String _searchQuery = '';
  // FocusNode yang persisten — tidak ikut rebuild
  final FocusNode           _searchFocus      = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // ── Data ─────────────────────────────────────────────────────────────────
  Map<int, String>  _categoryMap       = {};
  List<PlaceModel>  _allFavoritePlaces = [];
  bool              _dataLoaded        = false;

  @override
  void initState() {
    super.initState();
    _favService.loadFavorites();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final categories = await _categoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _categoryMap = {for (var c in categories) c.id: c.name};
        _dataLoaded  = true;
      });
    } catch (e) {
      AppLogger.error('Error loading favorites data: $e');
    }
  }

  Future<List<PlaceModel>> _loadFavoritePlaces(Set<int> ids) async {
    if (_dataLoaded && _allFavoritePlaces.isNotEmpty) {
      return _allFavoritePlaces.where((p) => ids.contains(p.id)).toList();
    }
    final futures = ids.map((id) => _placeService.getPlaceById(id));
    final results = await Future.wait(futures);
    final places  = results.whereType<PlaceModel>().toList();
    _allFavoritePlaces = places;
    return places;
  }

  /// Filter by NAMA tempat ATAU nama KATEGORI
  List<PlaceModel> _getFilteredPlaces(List<PlaceModel> places) {
    if (_searchQuery.isEmpty) return places;
    final q = _searchQuery.toLowerCase();
    return places.where((place) {
      final nameMatch     = place.name.toLowerCase().contains(q);
      final categoryName  = _categoryMap[place.categoryId] ?? '';
      final catMatch      = categoryName.toLowerCase().contains(q);
      return nameMatch || catMatch;
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      // GestureDetector agar tap di luar search bar menutup keyboard
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── Background shapes ─────────────────────────────────────
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EEFD),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 0,
              child: CustomPaint(
                size: const Size(120, 150),
                painter: CurvePainter(),
              ),
            ),

            // ── Main content ──────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    Text(
                      'Favorit',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B132B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Simpan tempat favorit untuk akses cepat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0B132B).withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Search bar — SELALU di luar FutureBuilder ────
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: _favService.favorites,
                      builder: (_, favs, _) {
                        // Sembunyikan search bar saat tidak ada favorit
                        if (favs.isEmpty) return const SizedBox.shrink();
                        return _buildSearchBar();
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── List area ────────────────────────────────────
                    Expanded(
                      child: ValueListenableBuilder<Set<int>>(
                        valueListenable: _favService.favorites,
                        builder: (context, favs, _) {
                          // Empty state
                          if (favs.isEmpty) return _buildEmptyState();

                          return FutureBuilder<List<PlaceModel>>(
                            future: _loadFavoritePlaces(favs),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState != ConnectionState.done) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1A6FDB),
                                  ),
                                );
                              }

                              final allPlaces = snapshot.data ?? [];
                              final places    = _getFilteredPlaces(allPlaces);

                              if (places.isEmpty) {
                                return _buildNoResults();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Count label
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      '${places.length} favorit ditemukan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // List
                                  Expanded(
                                    child: RefreshIndicator(
                                      color: const Color(0xFF1A6FDB),
                                      onRefresh: () async {
                                        _allFavoritePlaces = [];
                                        setState(() {});
                                      },
                                      child: ListView.builder(
                                        padding: const EdgeInsets.only(bottom: 100),
                                        itemCount: places.length,
                                        itemBuilder: (context, index) {
                                          final place = places[index];
                                          return PlaceCard(
                                            place: place,
                                            categoryName: _categoryMap[place.categoryId],
                                            distanceText: null,
                                            isFavorite: true,
                                            onFavoriteToggle: () async {
                                              await _favService.toggleFavorite(place.id);
                                              _allFavoritePlaces = [];
                                              setState(() {});
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  /// Search bar dengan FocusNode persisten agar tidak kehilangan fokus saat rebuild
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller:  _searchController,
        focusNode:   _searchFocus,        // ← FocusNode persisten
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF0B132B),
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama atau kategori...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 12),
            child: Icon(Icons.search_rounded, color: Color(0xFF1A6FDB), size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          // Tombol clear saat ada teks
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF9CA3AF), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF1A6FDB), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 40,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada favorit',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap ❤ pada tempat yang kamu suka\nuntuk menambah favorit.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE8EEFD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Color(0xFF1A6FDB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil untuk',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"$_searchQuery"',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B132B),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Curve Painter (sama seperti categories_screen) ────────────────────────────
class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color      = const Color(0xFFD4FF59)
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      const Offset(20, 20), 8,
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
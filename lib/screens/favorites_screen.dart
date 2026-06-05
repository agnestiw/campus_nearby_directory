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
  final FavoritesService _favService = FavoritesService();
  final PlaceService _placeService = PlaceService();
  final CategoryService _categoryService = CategoryService();

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Map<int, String> _categoryMap = {};
  List<PlaceModel> _allFavoritePlaces = [];
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load categories and all places at once
      final categories = await _categoryService.getCategories();
      setState(() {
        _categoryMap = {for (var c in categories) c.id: c.name};
      });
      
      // Mark as loaded so we don't reload
      setState(() => _dataLoaded = true);
    } catch (e) {
      AppLogger.error('Error loading favorites data: $e');
    }
  }

  Future<List<PlaceModel>> _loadFavoritePlaces(Set<int> ids) async {
    // If already loaded, return cached data filtered by current ids
    if (_dataLoaded && _allFavoritePlaces.isNotEmpty) {
      return _allFavoritePlaces.where((p) => ids.contains(p.id)).toList();
    }

    // Otherwise fetch from database
    final futures = ids.map((id) => _placeService.getPlaceById(id));
    final results = await Future.wait(futures);
    final places = results.whereType<PlaceModel>().toList();
    
    // Cache for future use
    _allFavoritePlaces = places;
    return places;
  }

  List<PlaceModel> _getFilteredPlaces(List<PlaceModel> places) {
    if (_searchQuery.isEmpty) return places;
    return places
        .where((place) => place.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: ValueListenableBuilder<Set<int>>(
        valueListenable: _favService.favorites,
        builder: (context, favs, _) {
          if (favs.isEmpty) {
            return Stack(
              children: [
                // Background Abstract Shapes
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
                // Empty State Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                color: const Color(0xFF0B132B).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 100),
                        
                        // Empty State Icon
                        Center(
                          child: Container(
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
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Empty State Text
                        Center(
                          child: Column(
                            children: [
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
                                'Tap ❤ pada tempat yang kamu suka untuk menambah favorit.',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return FutureBuilder<List<PlaceModel>>(
            future: _loadFavoritePlaces(favs),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final allPlaces = snapshot.data ?? [];
              final places = _getFilteredPlaces(allPlaces);
              
              if (places.isEmpty && _searchQuery.isNotEmpty) {
                return Stack(
                  children: [
                    // Background Abstract Shapes
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
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            
                            // Header
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                    color: const Color(0xFF0B132B).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Search Bar
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Cari favorit...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 20, right: 12),
                                    child: Icon(Icons.search, color: Color(0xFF1A6FDB), size: 22),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 50),
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
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 80),
                            
                            // No Results
                            Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada hasil',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0B132B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              return Stack(
                children: [
                  // Background Abstract Shapes
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
                  
                  // Main Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Header
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  color: const Color(0xFF0B132B).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Search Bar
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Cari favorit...',
                                hintStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 20, right: 12),
                                  child: Icon(Icons.search, color: Color(0xFF1A6FDB), size: 22),
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 50),
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
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Results Count
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${places.length} favorit',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // List of Favorites
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async { setState(() {}); },
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
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFFD4FF59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    var path = Path();
    
    // Start with a small circle
    canvas.drawCircle(const Offset(20, 20), 8, paint..style = PaintingStyle.fill);
    
    // Draw the curve
    paint.style = PaintingStyle.stroke;
    path.moveTo(20, 20);
    path.quadraticBezierTo(size.width * 0.7, 10, size.width, size.height);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../models/category_model.dart';
import '../models/place_model.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import '../services/favorites_service.dart';
import '../utils/distance_helper.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/place_card.dart';
import 'place_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaceService _placeService = PlaceService();
  final CategoryService _categoryService = CategoryService();
  final LocationService _locationService = LocationService();
  final FavoritesService _favService = FavoritesService();

  List<PlaceModel> _allPlaces = [];
  List<PlaceModel> _filteredPlaces = [];
  List<CategoryModel> _categories = [];
  Map<int, String> _categoryMap = {};

  Position? _currentPosition;
  String _searchKeyword = '';
  int? _selectedCategoryId;

  bool _isLoading = true;
  String? _errorMessage;

  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _searchController = TextEditingController();
    _startCarousel();

    _favService.loadFavorites();
    _favService.favorites.addListener(_onFavoritesChanged);

    _loadData();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _favService.favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      final spots = _spotOfTheDayPlaces;
      if (spots.isNotEmpty) {
        setState(() {
          _currentCarouselIndex = (_currentCarouselIndex + 1) % spots.length;
        });
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentCarouselIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  List<PlaceModel> get _spotOfTheDayPlaces {
    final sorted = List<PlaceModel>.from(_allPlaces);
    sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sorted.take(3).toList();
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    final favIds = _favService.favorites.value;
    setState(() {
      for (final place in _allPlaces) {
        place.isFavorite = favIds.contains(place.id);
      }
      for (final place in _filteredPlaces) {
        place.isFavorite = favIds.contains(place.id);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _categoryService.getCategories(),
        _placeService.getPlaces(),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final places = results[1] as List<PlaceModel>;

      final categoryMap = {for (var c in categories) c.id: c.name};

      _loadLocation();

      setState(() {
        _categories = categories;
        _categoryMap = categoryMap;
        _allPlaces = places;
        _filteredPlaces = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (result.isSuccess && mounted) {
      setState(() => _currentPosition = result.position);
      _applyFilter();
    }
  }

  void _applyFilter() {
    List<PlaceModel> filtered = _allPlaces;

    // Filter by category
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // Filter by search keyword
    if (_searchKeyword.isNotEmpty) {
      final kw = _searchKeyword.toLowerCase();
      filtered = filtered.where((p) {
        final catName = _categoryMap[p.categoryId]?.toLowerCase() ?? '';
        return p.name.toLowerCase().contains(kw) ||
               p.address.toLowerCase().contains(kw) ||
               catName.contains(kw);
      }).toList();
    }

    // Sort by distance if location available
    if (_currentPosition != null) {
      filtered.sort((a, b) {
        final distA = DistanceHelper.calculateDistance(
          startLat: _currentPosition!.latitude,
          startLng: _currentPosition!.longitude,
          endLat: a.latitude,
          endLng: a.longitude,
        );
        final distB = DistanceHelper.calculateDistance(
          startLat: _currentPosition!.latitude,
          startLng: _currentPosition!.longitude,
          endLat: b.latitude,
          endLng: b.longitude,
        );
        return distA.compareTo(distB);
      });
    }

    setState(() => _filteredPlaces = filtered);
  }

  String? _getDistance(PlaceModel place) {
    if (_currentPosition == null) return null;
    final meters = DistanceHelper.calculateDistance(
      startLat: _currentPosition!.latitude,
      startLng: _currentPosition!.longitude,
      endLat: place.latitude,
      endLng: place.longitude,
    );
    return DistanceHelper.formatDistance(meters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [
          // Background Abstract Shapes (like Categories Screen)
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
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Beranda',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B132B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Temukan tempat dan layanan terdekat',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0B132B).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Search Bar ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
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
                            _searchKeyword = value;
                          });
                          _applyFilter();
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari cafe, fotokopi, ATM...',
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
                          suffixIcon: _searchKeyword.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchKeyword = '';
                                    });
                                    _applyFilter();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 16),
                                    child: Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
                                  ),
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
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),

                // Show active filter indicator
                if (_selectedCategoryId != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4FF59).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4FF59), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_alt_rounded, color: Color(0xFF1A6FDB), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Filter: ${_categoryMap[_selectedCategoryId]}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A6FDB),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                });
                                _applyFilter();
                              },
                              child: const Icon(Icons.close_rounded, color: Color(0xFF1A6FDB), size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Spot of the Day ────────────────────
                if (!_isLoading && _searchKeyword.isEmpty && _selectedCategoryId == null)
                  SliverToBoxAdapter(child: _buildSpotCarousel()),

                if (!_isLoading && _searchKeyword.isEmpty && _selectedCategoryId == null)
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Section Title ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _searchKeyword.isEmpty && _selectedCategoryId == null
                          ? 'Rekomendasi Terdekat'
                          : 'Hasil Pencarian',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B132B),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Content ──────────────────────────────
                _buildContent(),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCarousel() {
    final spots = _spotOfTheDayPlaces;
    if (spots.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spot Unggulan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              itemCount: spots.length,
              itemBuilder: (context, index) {
                return _buildSpotCard(spots[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(spots.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentCarouselIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentCarouselIndex == index
                      ? const Color(0xFF1A6FDB)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(PlaceModel place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(
              place: place,
              categoryName: _categoryMap[place.categoryId],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(place.photoUrl ?? ''),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
            
            // TOP BADGES
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFF1A6FDB), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Unggulan',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A6FDB),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Favorite button
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () async {
                  await _favService.toggleFavorite(place.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      )
                    ]
                  ),
                  child: Icon(
                    place.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: const Color(0xFFE53E3E),
                    size: 18,
                  ),
                ),
              ),
            ),
            
            // BOTTOM CONTENT
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4FF59),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _categoryMap[place.categoryId] ?? 'Kategori',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0B132B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Place name
                    Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${place.rating?.toStringAsFixed(1) ?? '0.0'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildContent() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          type: ErrorType.network,
          onRetry: _loadData,
        ),
      );
    }

    if (_filteredPlaces.isEmpty) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          type: ErrorType.empty,
          onRetry: () {
            setState(() {
              _searchKeyword = '';
            });
            _applyFilter();
          },
        ),
      );
    }

    // Since Spot of the Day is now a top 3 rated carousel separate from the list, we show all filteredPlaces in Rekomendasi
    final listPlaces = _filteredPlaces;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final place = listPlaces[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PlaceCard(
                place: place,
                categoryName: _categoryMap[place.categoryId],
                distanceText: _getDistance(place),
                isFavorite: place.isFavorite,
                onFavoriteToggle: () async {
                  await _favService.toggleFavorite(place.id);
                },
              ),
            );
          },
          childCount: listPlaces.length,
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFFE8EEFD)
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CurvePainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category_model.dart';
import '../models/place_model.dart';
import '../services/category_service.dart';
import '../services/place_service.dart';
import '../services/favorites_service.dart';
import '../utils/distance_helper.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/place_card.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  final PlaceService _placeService = PlaceService();
  final LocationService _locationService = LocationService();
  final FavoritesService _favService = FavoritesService();

  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  CategoryModel? _selectedCategory;
  List<PlaceModel> _categoryPlaces = [];
  bool _isLoadingPlaces = false;

  Position? _currentPosition;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where((cat) => cat.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _favService.loadFavorites();
    _favService.favorites.addListener(_onFavoritesChanged);
    _loadCategories();
    _loadLocation();
  }

  @override
  void dispose() {
    _favService.favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    final favIds = _favService.favorites.value;
    setState(() {
      for (final place in _categoryPlaces) {
        place.isFavorite = favIds.contains(place.id);
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getCategories();
      final allPlaces = await _placeService.getPlaces();

      for (var cat in cats) {
        cat.placeCount = allPlaces.where((p) => p.categoryId == cat.id).length;
      }

      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (result.isSuccess && mounted) {
      setState(() => _currentPosition = result.position);
    }
  }

  Future<void> _selectCategory(CategoryModel cat) async {
    setState(() {
      _selectedCategory = cat;
      _isLoadingPlaces = true;
      _categoryPlaces = [];
    });

    try {
      final places = await _placeService.getPlacesByCategory(cat.id);
      setState(() {
        _categoryPlaces = places;
        _isLoadingPlaces = false;
      });
    } catch (e) {
      setState(() => _isLoadingPlaces = false);
    }
  }

  String? _getDistance(PlaceModel place) {
    if (_currentPosition == null) return null;
    final m = DistanceHelper.calculateDistance(
      startLat: _currentPosition!.latitude,
      startLng: _currentPosition!.longitude,
      endLat: place.latitude,
      endLng: place.longitude,
    );
    return DistanceHelper.formatDistance(m);
  }

  Widget _buildCategoryIcon(String name) {
    final lower = name.toLowerCase();
    
    // 1. Kesehatan: Love +
    if (lower.contains('kesehatan') || lower.contains('klinik')) {
      return Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.favorite_border_rounded, color: Color(0xFF1A6FDB), size: 28),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              color: Colors.white,
              child: const Icon(Icons.add, color: Color(0xFFD4FF59), size: 16),
            ),
          ),
        ],
      );
    }
    
    // 2. Kos: Bed (Color the pillow / left part)
    if (lower.contains('kos') || lower.contains('penginapan')) {
      return _buildShaderIcon(
        Icons.bed_outlined, 
        begin: Alignment.centerLeft, 
        end: Alignment.centerRight, 
        stop: 0.35,
      );
    }
    
    // 3. Minimarket: Storefront (Color the roof / top part)
    if (lower.contains('minimarket') || lower.contains('toko')) {
      return _buildShaderIcon(
        Icons.storefront_outlined, 
        begin: Alignment.topCenter, 
        end: Alignment.bottomCenter, 
        stop: 0.38,
      );
    }
    
    // 4. ATM: Credit Card (Color the chip / bottom right part)
    if (lower.contains('atm') || lower.contains('bank')) {
      return _buildShaderIcon(
        Icons.credit_card_outlined, 
        begin: Alignment.bottomRight, 
        end: Alignment.topLeft, 
        stop: 0.35,
      );
    }
    
    // 5. Makan: Restaurant (Color the spoon / left part)
    if (lower.contains('makan') || lower.contains('cafe') || lower.contains('kantin')) {
      return _buildShaderIcon(
        Icons.restaurant_outlined, 
        begin: Alignment.centerLeft, 
        end: Alignment.centerRight, 
        stop: 0.4,
      );
    }
    
    // Default
    return _buildShaderIcon(
      Icons.category_outlined,
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      stop: 0.3,
    );
  }

  Widget _buildShaderIcon(IconData icon, {required Alignment begin, required Alignment end, required double stop}) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: begin,
          end: end,
          colors: const [Color(0xFFD4FF59), Color(0xFFD4FF59), Color(0xFF1A6FDB), Color(0xFF1A6FDB)],
          stops: [0.0, stop, stop, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If a category is selected, show places list. Otherwise, show categories.
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(
                  type: ErrorType.network,
                  onRetry: _loadCategories,
                )
              : _selectedCategory == null
                  ? _buildCategoryView()
                  : _buildPlaceListView(),
    );
  }

  Widget _buildCategoryView() {
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
                      'Kategori',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B132B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Temukan layanan dan tempat di kampus',
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
                      hintText: 'Cari kategori...',
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
                
                const SizedBox(height: 32),
                
                // List of Categories
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // space for bottom nav
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return GestureDetector(
                        onTap: () => _selectCategory(category),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon Container
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE8EEFD),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: _buildCategoryIcon(category.name),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Text Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name[0].toUpperCase() + category.name.substring(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0B132B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          color: Color(0xFF64748B),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${category.placeCount} tempat',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Arrow Button
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4FF59),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF0B132B),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceListView() {
    return Column(
      children: [
        // Top Header matching the new design
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 16, right: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                    _categoryPlaces = [];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0B132B)),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_selectedCategory!.name[0].toUpperCase()}${_selectedCategory!.name.substring(1)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B132B),
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        
        if (_isLoadingPlaces)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_categoryPlaces.isEmpty)
          const Expanded(child: ErrorStateWidget(type: ErrorType.empty))
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    '${_categoryPlaces.length} tempat ditemukan',
                    style: GoogleFonts.poppins(
                      fontSize: 14, 
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                    itemCount: _categoryPlaces.length,
                    itemBuilder: (context, index) {
                      final place = _categoryPlaces[index];
                      return PlaceCard(
                        place: place,
                        categoryName: _selectedCategory?.name,
                        distanceText: _getDistance(place),
                        isFavorite: place.isFavorite,
                        onFavoriteToggle: () async {
                          await _favService.toggleFavorite(place.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
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
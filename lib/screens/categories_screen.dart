import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
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

  @override
  void initState() {
    super.initState();

    _favService.loadFavorites();

    _favService.favorites.addListener(
      _onFavoritesChanged,
    );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _selectedCategory != null 
              ? '${_selectedCategory!.name[0].toUpperCase()}${_selectedCategory!.name.substring(1)}'
              : 'Kategori',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
                onPressed: () => setState(() {
                  _selectedCategory = null;
                  _categoryPlaces = [];
                }),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(
                  type: ErrorType.network,
                  onRetry: _loadCategories,
                )
              : _selectedCategory == null
                  ? _buildCategoryGrid()
                  : _buildPlaceList(),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih kategori tempat yang ingin kamu jelajahi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.9,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final color = AppTheme.getCategoryColor(cat.name);
                final icon = AppTheme.getCategoryIcon(cat.name);

                return GestureDetector(
                  onTap: () => _selectCategory(cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Stack(
                      children: [
                        // Decorative elegant abstract shape on top right
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 28),
                              ),
                              Text(
                                cat.name[0].toUpperCase() + cat.name.substring(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
    );
  }

  Widget _buildPlaceList() {
    if (_isLoadingPlaces) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoryPlaces.isEmpty) {
      return const ErrorStateWidget(type: ErrorType.empty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            '${_categoryPlaces.length} tempat ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 14, 
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
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
    );
  }
}
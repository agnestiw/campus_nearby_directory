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
import '../widgets/category_overlap_list.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF8E8E93),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: CategoryOverlapList(
                categories: _filteredCategories,
                onCategorySelected: _selectCategory,
              ),
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
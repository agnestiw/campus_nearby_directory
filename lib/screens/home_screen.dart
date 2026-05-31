import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/category_model.dart';
import '../models/place_model.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import '../services/favorites_service.dart';
import '../utils/distance_helper.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/place_card.dart';
import '../widgets/search_bar_widget.dart';

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
  Map<int, String> _categoryMap = {}; // id -> name

  Position? _currentPosition;
  int? _selectedCategoryId;
  String _searchKeyword = '';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _favService.favorites.addListener(_onFavoritesChanged);
    _loadData();
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
      // Load categories dan places secara parallel
      final results = await Future.wait([
        _categoryService.getCategories(),
        _placeService.getPlaces(),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final places = results[1] as List<PlaceModel>;

      // Build category map untuk lookup cepat
      final categoryMap = {for (var c in categories) c.id: c.name};

      // Load GPS (non-blocking — tidak gagalkan seluruh halaman)
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
    }
  }

  void _applyFilter() {
    List<PlaceModel> filtered = _allPlaces;

    // Filter kategori
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((p) => p.categoryId == _selectedCategoryId)
          .toList();
    }

    // Filter search
    if (_searchKeyword.isNotEmpty) {
      final kw = _searchKeyword.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(kw) ||
              p.address.toLowerCase().contains(kw))
          .toList();
    }

    // Urutkan berdasarkan jarak jika GPS tersedia
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────
            _buildHeader(),

            // ── Search ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SearchBarWidget(
                hint: 'Cari cafe, fotokopi, ATM...',
                onChanged: (value) {
                  _searchKeyword = value;
                  _applyFilter();
                },
              ),
            ),

            // ── Category Filter ───────────────────────
            if (_categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CategoryFilterWidget(
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (id) {
                    _selectedCategoryId = id;
                    _applyFilter();
                  },
                ),
              ),

            // ── Result count ─────────────────────────
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${_filteredPlaces.length} tempat ditemukan'
                  '${_currentPosition != null ? ' • diurutkan berdasarkan jarak' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),

            // ── Content ──────────────────────────────
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📍',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Campus Nearby',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              // GPS indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _currentPosition != null
                      ? const Color(0xFF0F9E75).withOpacity(0.1)
                      : const Color(0xFF9CA3AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentPosition != null
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      size: 12,
                      color: _currentPosition != null
                          ? const Color(0xFF0F9E75)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentPosition != null ? 'GPS Aktif' : 'GPS...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _currentPosition != null
                            ? const Color(0xFF0F9E75)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Temukan tempat di sekitar kampusmu',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        type: ErrorType.network,
        onRetry: _loadData,
      );
    }

    if (_filteredPlaces.isEmpty) {
      return ErrorStateWidget(
        type: ErrorType.empty,
        onRetry: () {
          setState(() {
            _searchKeyword = '';
            _selectedCategoryId = null;
          });
          _applyFilter();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _filteredPlaces.length,
        itemBuilder: (context, index) {
          final place = _filteredPlaces[index];
          return PlaceCard(
            place: place,
            categoryName: _categoryMap[place.categoryId],
            distanceText: _getDistance(place),
            isFavorite: place.isFavorite,
            onFavoriteToggle: () async {
              await _favService.toggleFavorite(place.id);
            },
          );
        },
      ),
    );
  }
}
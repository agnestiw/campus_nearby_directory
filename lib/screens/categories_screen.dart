import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/category_model.dart';
import '../models/place_model.dart';
import '../services/category_service.dart';
import '../services/place_service.dart';
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
    _loadCategories();
    _loadLocation();
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
      appBar: AppBar(
        title: const Text('Kategori'),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih kategori untuk melihat tempat',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cat.name[0].toUpperCase() + cat.name.substring(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_categoryPlaces.length} tempat ditemukan',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _categoryPlaces.length,
            itemBuilder: (context, index) {
              final place = _categoryPlaces[index];
              return PlaceCard(
                place: place,
                categoryName: _selectedCategory?.name,
                distanceText: _getDistance(place),
              );
            },
          ),
        ),
      ],
    );
  }
}
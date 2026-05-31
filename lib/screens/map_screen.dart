import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_theme.dart';
import '../models/category_model.dart';
import '../models/place_model.dart';
import '../screens/place_detail_screen.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import '../services/routing_service.dart';
import '../utils/distance_helper.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/error_state_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PlaceService _placeService = PlaceService();
  final CategoryService _categoryService = CategoryService();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  List<PlaceModel> _places = [];
  List<CategoryModel> _categories = [];
  Map<int, String> _categoryMap = {};

  Position? _currentPosition;
  int? _selectedCategoryId;

  bool _isLoading = true;
  bool _isLoadingLocation = false;
  String? _errorMessage;

  // Default center: Surabaya
  static const _defaultCenter = LatLng(-7.2698, 112.7590);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
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

      setState(() {
        _categories = categories;
        _categoryMap = {for (var c in categories) c.id: c.name};
        _places = places;
        _isLoading = false;
      });

      // Load GPS setelah data selesai
      _loadLocation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _isLoadingLocation = true);

    final result = await _locationService.getCurrentLocation();

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _currentPosition = result.position;
        _isLoadingLocation = false;
      });

      // Pindahkan kamera ke posisi user
      _mapController.move(
        LatLng(result.position!.latitude, result.position!.longitude),
        15,
      );
    } else {
      setState(() => _isLoadingLocation = false);

      // Tampilkan snackbar berdasarkan error
      if (!mounted) return;
      _showLocationError(result.error!);
    }
  }

  void _showLocationError(LocationError error) {
    String message;
    VoidCallback? action;
    String? actionLabel;

    switch (error) {
      case LocationError.serviceDisabled:
        message = 'GPS tidak aktif. Aktifkan di pengaturan.';
        action = _locationService.openLocationSettings;
        actionLabel = 'Buka';
        break;
      case LocationError.permissionDenied:
        message = 'Izin lokasi ditolak.';
        action = _loadLocation;
        actionLabel = 'Coba Lagi';
        break;
      case LocationError.permissionDeniedForever:
        message = 'Izin lokasi ditolak permanen. Buka pengaturan.';
        action = _locationService.openAppSettings;
        actionLabel = 'Pengaturan';
        break;
      case LocationError.unknown:
        message = 'Gagal mendapatkan lokasi.';
        action = _loadLocation;
        actionLabel = 'Coba Lagi';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action != null
            ? SnackBarAction(label: actionLabel!, onPressed: action)
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _filterByCategory(int? categoryId) async {
    setState(() => _selectedCategoryId = categoryId);

    try {
      final places = categoryId == null
          ? await _placeService.getPlaces()
          : await _placeService.getPlacesByCategory(categoryId);

      setState(() => _places = places);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  void _showPlaceBottomSheet(PlaceModel place) {
    final catName = _categoryMap[place.categoryId];
    final catColor = AppTheme.getCategoryColor(catName ?? '');
    final catIcon = AppTheme.getCategoryIcon(catName ?? '');

    String? distanceText;
    if (_currentPosition != null) {
      final meters = DistanceHelper.calculateDistance(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        endLat: place.latitude,
        endLng: place.longitude,
      );
      distanceText = DistanceHelper.formatDistance(meters);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category badge + name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(catIcon, color: catColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        if (catName != null)
                          Text(
                            catName,
                            style: TextStyle(
                              fontSize: 12,
                              color: catColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Rating + Distance + Jam
              Row(
                children: [
                  if (place.rating != null) ...[
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 15,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      place.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (distanceText != null) ...[
                    const Icon(
                      Icons.near_me_rounded,
                      size: 13,
                      color: Color(0xFF1A6FDB),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A6FDB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (place.openHour != null) ...[
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      place.openHour!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  // Detail button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(
                              place: place,
                              categoryName: catName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A6FDB),
                        side: const BorderSide(color: Color(0xFF1A6FDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Routing button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final success = await RoutingService.openRoute(
                          destLat: place.latitude,
                          destLng: place.longitude,
                          destName: place.name,
                        );
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tidak bisa membuka aplikasi peta.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Buka Rute'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6FDB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kampus'),
        actions: [
          // Tombol GPS — kembali ke lokasi user
          if (_currentPosition != null)
            IconButton(
              onPressed: () {
                _mapController.move(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  16,
                );
              },
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'Lokasi Saya',
            ),
          // Refresh
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category filter ───────────────────────────
          if (_categories.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CategoryFilterWidget(
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: _filterByCategory,
              ),
            ),

          // ── Map ──────────────────────────────────────
          Expanded(
            child: _buildMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        type: ErrorType.network,
        onRetry: _loadAll,
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null
                ? LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  )
                : _defaultCenter,
            initialZoom: 15,
          ),
          children: [
            // ── OSM Tile Layer ────────────────────
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.campus_nearby_directory',
            ),

            // ── Place Markers ─────────────────────
            MarkerLayer(
              markers: _places.map((place) {
                final catName = _categoryMap[place.categoryId];
                final catColor = AppTheme.getCategoryColor(catName ?? '');
                final catIcon = AppTheme.getCategoryIcon(catName ?? '');

                return Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _showPlaceBottomSheet(place),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: catColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(catIcon, color: Colors.white, size: 18),
                        ),
                        // Pin tail
                        Container(
                          width: 2,
                          height: 6,
                          color: catColor,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── User Location Marker ──────────────
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6FDB).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Inner dot
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6FDB),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A6FDB).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        // ── Loading GPS overlay ───────────────────────
        if (_isLoadingLocation)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mencari lokasi GPS...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Place count badge ─────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              '${_places.length} tempat',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A6FDB),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
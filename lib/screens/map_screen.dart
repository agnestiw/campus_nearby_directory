import 'dart:math' as math;

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

  // ── Routing state ────────────────────────────────
  PlaceModel? _activeRouteDest;
  RouteResult? _activeRoute;
  bool _isLoadingRoute = false;

  static const _defaultCenter = LatLng(-7.2698, 112.7590);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ─────────────────────────────────────────────────
  // LOAD DATA
  // ─────────────────────────────────────────────────
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
      _mapController.move(
        LatLng(result.position!.latitude, result.position!.longitude),
        15,
      );
    } else {
      setState(() => _isLoadingLocation = false);
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

    if (!mounted) return;
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
        SnackBar(content: Text('Gagal memuat: $e')),
      );
    }
  }

  // ─────────────────────────────────────────────────
  // ROUTING — ambil polyline dari OSRM
  // ─────────────────────────────────────────────────
  Future<void> _startRoute(PlaceModel destination) async {
    if (_currentPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS belum tersedia. Tunggu sebentar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _activeRouteDest = destination;
      _activeRoute = null;
    });

    final origin = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    final dest = LatLng(destination.latitude, destination.longitude);

    final route = await OsrmRoutingService.getRoute(
      origin: origin,
      destination: dest,
    );

    if (!mounted) return;

    if (route == null) {
      setState(() {
        _isLoadingRoute = false;
        _activeRoute = null;
        _activeRouteDest = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil rute. Periksa koneksi internet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _activeRoute = route;
      _isLoadingRoute = false;
    });

    // Fit peta agar origin + dest keduanya terlihat
    final bounds = LatLngBounds.fromPoints([origin, dest]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _activeRoute = null;
      _activeRouteDest = null;
      _isLoadingRoute = false;
    });
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15,
      );
    }
  }

  // ─────────────────────────────────────────────────
  // BOTTOM SHEET per marker
  // ─────────────────────────────────────────────────
  void _showPlaceBottomSheet(PlaceModel place) {
    final catName = _categoryMap[place.categoryId];
    final catColor = AppTheme.getCategoryColor(catName ?? '');
    final catIcon = AppTheme.getCategoryIcon(catName ?? '');

    String? distanceText;
    if (_currentPosition != null) {
      final m = DistanceHelper.calculateDistance(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        endLat: place.latitude,
        endLng: place.longitude,
      );
      distanceText = DistanceHelper.formatDistance(m);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (catName != null)
                        Text(catName, style: TextStyle(fontSize: 12, color: catColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place.address,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    maxLines: 2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                if (place.rating != null) ...[
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                  const SizedBox(width: 3),
                  Text(place.rating!.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                ],
                if (distanceText != null) ...[
                  const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF1A6FDB)),
                  const SizedBox(width: 3),
                  Text(distanceText,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1A6FDB), fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                ],
                if (place.openHour != null) ...[
                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 3),
                  Text(place.openHour!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(place: place, categoryName: catName),
                      ));
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A6FDB),
                      side: const BorderSide(color: Color(0xFF1A6FDB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startRoute(place);
                    },
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: const Text('Buka Rute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6FDB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kampus'),
        actions: [
          if (_currentPosition != null)
            IconButton(
              onPressed: () => _mapController.move(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16,
              ),
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'Lokasi Saya',
            ),
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(child: _buildMapBody()),
        ],
      ),
    );
  }

  Widget _buildMapBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return ErrorStateWidget(type: ErrorType.network, onRetry: _loadAll);

    return Stack(
      children: [
        // ── PETA ────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : _defaultCenter,
            initialZoom: 15,
            onTap: (_, __) {
              if (_activeRoute != null) _clearRoute();
            },
          ),
          children: [
            // Tiles OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.campus_nearby_directory',
            ),

            // ── Polyline rute ────────────────────────
            if (_activeRoute != null)
              PolylineLayer(
                polylines: [
                  // Glow / shadow di belakang
                  Polyline(
                    points: _activeRoute!.points,
                    strokeWidth: 10,
                    color: const Color(0xFF1A6FDB).withOpacity(0.2),
                  ),
                  // Garis utama
                  Polyline(
                    points: _activeRoute!.points,
                    strokeWidth: 5,
                    color: const Color(0xFF1A6FDB),
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            // ── Marker tempat ─────────────────────────
            MarkerLayer(
              markers: _places.map((place) {
                final catName = _categoryMap[place.categoryId];
                final catColor = AppTheme.getCategoryColor(catName ?? '');
                final catIcon = AppTheme.getCategoryIcon(catName ?? '');
                final isActive = _activeRouteDest?.id == place.id;

                return Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: isActive ? 56 : 44,
                  height: isActive ? 60 : 50,
                  child: GestureDetector(
                    onTap: () => _showPlaceBottomSheet(place),
                    child: Column(
                      children: [
                        Container(
                          width: isActive ? 44 : 34,
                          height: isActive ? 44 : 34,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF1A6FDB) : catColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isActive ? 3 : 2),
                            boxShadow: [
                              BoxShadow(
                                color: (isActive ? const Color(0xFF1A6FDB) : catColor).withOpacity(0.45),
                                blurRadius: isActive ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isActive ? Icons.flag_rounded : catIcon,
                            color: Colors.white,
                            size: isActive ? 22 : 17,
                          ),
                        ),
                        Container(
                          width: 2.5,
                          height: isActive ? 10 : 7,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF1A6FDB) : catColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── Marker posisi user ────────────────────
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 60, height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6FDB).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6FDB).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6FDB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
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

        // ── Loading GPS ───────────────────────────────
        if (_isLoadingLocation)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Center(child: _buildPill(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Mencari lokasi GPS...', style: TextStyle(fontSize: 12)),
                ],
              ),
            )),
          ),

        // ── Loading route ─────────────────────────────
        if (_isLoadingRoute)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Center(child: _buildPill(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A6FDB))),
                  SizedBox(width: 8),
                  Text('Menghitung rute...', style: TextStyle(fontSize: 12, color: Color(0xFF1A6FDB))),
                ],
              ),
            )),
          ),

        // ── Route info card ───────────────────────────
        if (_activeRoute != null && _activeRouteDest != null)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildRouteCard(),
          ),

        // ── Place count badge ─────────────────────────
        if (_activeRoute == null && !_isLoadingRoute)
          Positioned(
            top: 12, right: 12,
            child: _buildPill(
              child: Text(
                '${_places.length} tempat',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A6FDB)),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // ROUTE CARD — mirip Google Maps
  // ─────────────────────────────────────────────────
  Widget _buildRouteCard() {
    final route = _activeRoute!;
    final dest = _activeRouteDest!;
    final catName = _categoryMap[dest.categoryId];
    final catColor = AppTheme.getCategoryColor(catName ?? '');
    final catIcon = AppTheme.getCategoryIcon(catName ?? '');

    final bearing = _currentPosition != null
        ? _getBearing(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            dest.latitude,
            dest.longitude,
          )
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x28000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header tujuan
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(catIcon, color: catColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rute menuju', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          Text(dest.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Tombol tutup
                    GestureDetector(
                      onTap: _clearRoute,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats: jarak + waktu
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.straighten_rounded,
                      color: const Color(0xFF1A6FDB),
                      label: route.formattedDistance,
                      sublabel: 'Jarak',
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      icon: Icons.directions_walk_rounded,
                      color: const Color(0xFF0F9E75),
                      label: route.formattedDuration,
                      sublabel: 'Jalan kaki',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('via OSM', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Arah kompas
                if (bearing != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(_bearingToIcon(bearing), size: 20, color: const Color(0xFF1A6FDB)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menuju arah ${_bearingToLabel(bearing)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                            ),
                            const Text(
                              'Ikuti garis biru di peta',
                              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color color,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              Text(sublabel, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: child,
    );
  }

  // ─────────────────────────────────────────────────
  // HELPERS — bearing / arah kompas
  // ─────────────────────────────────────────────────
  double _getBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final lat1R = lat1 * math.pi / 180;
    final lat2R = lat2 * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2R);
    final x = math.cos(lat1R) * math.sin(lat2R) -
        math.sin(lat1R) * math.cos(lat2R) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  String _bearingToLabel(double bearing) {
    if (bearing < 22.5 || bearing >= 337.5) return 'Utara';
    if (bearing < 67.5) return 'Timur Laut';
    if (bearing < 112.5) return 'Timur';
    if (bearing < 157.5) return 'Tenggara';
    if (bearing < 202.5) return 'Selatan';
    if (bearing < 247.5) return 'Barat Daya';
    if (bearing < 292.5) return 'Barat';
    return 'Barat Laut';
  }

  IconData _bearingToIcon(double bearing) {
    if (bearing < 22.5 || bearing >= 337.5) return Icons.arrow_upward_rounded;
    if (bearing < 67.5) return Icons.north_east_rounded;
    if (bearing < 112.5) return Icons.arrow_forward_rounded;
    if (bearing < 157.5) return Icons.south_east_rounded;
    if (bearing < 202.5) return Icons.arrow_downward_rounded;
    if (bearing < 247.5) return Icons.south_west_rounded;
    if (bearing < 292.5) return Icons.arrow_back_rounded;
    return Icons.north_west_rounded;
  }
}
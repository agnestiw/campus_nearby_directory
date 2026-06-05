import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../models/category_model.dart';
import '../models/place_model.dart';
import '../screens/place_detail_screen.dart';
import '../services/category_service.dart';
import '../services/favorites_service.dart';
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

  final FavoritesService _favService = FavoritesService();
  int? _selectedPlaceIndex;

  // ── Routing state ────────────────────────────────
  PlaceModel? _activeRouteDest;
  RouteResult? _activeRoute;
  bool _isLoadingRoute = false;

  bool _showCarousel = false;
  final PageController _carouselController = PageController(viewportFraction: 0.9);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _defaultCenter = LatLng(-7.2698, 112.7590);

  @override
  void initState() {
    super.initState();
    _favService.loadFavorites();
    _favService.favorites.addListener(_onFavoritesChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _favService.favorites.removeListener(_onFavoritesChanged);
    _carouselController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
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
    _applySearch();
  }

  Future<void> _applySearch() async {
    setState(() => _isLoading = true);
    try {
      final places = _selectedCategoryId == null
          ? await _placeService.getPlaces()
          : await _placeService.getPlacesByCategory(_selectedCategoryId!);
          
      final filtered = _searchQuery.trim().isEmpty 
          ? places 
          : places.where((p) {
              final q = _searchQuery.toLowerCase();
              final catName = (_categoryMap[p.categoryId] ?? '').toLowerCase();
              return p.name.toLowerCase().contains(q) || 
                     p.address.toLowerCase().contains(q) ||
                     catName.contains(q);
            }).toList();
          
      setState(() {
        _places = filtered;
        _isLoading = false;
      });
      
      if (filtered.isNotEmpty && _searchQuery.trim().isNotEmpty) {
        final first = filtered.first;
        _mapController.move(LatLng(first.latitude, first.longitude), 16);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: const Color(0xFF1A6FDB), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B132B),
                        ),
                      ),
                      if (catName != null)
                        Text(catName, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A6FDB), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.address,
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
                    maxLines: 2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (place.rating != null) ...[
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 4),
                  Text(place.rating!.toStringAsFixed(1),
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0B132B))),
                  const SizedBox(width: 16),
                ],
                if (distanceText != null) ...[
                  const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF1A6FDB)),
                  const SizedBox(width: 4),
                  Text(distanceText,
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A6FDB), fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                ],
                if (place.openHour != null) ...[
                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(place.openHour!, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
                ],
              ],
            ),

            const SizedBox(height: 24),

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
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: Text('Detail', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B132B),
                      side: const BorderSide(color: Color(0xFF0B132B), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startRoute(place);
                    },
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: Text('Buka Rute', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4FF59),
                      foregroundColor: const Color(0xFF0B132B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. MAP
          _buildMapBody(),

          // 2. TOP HEADER
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopHeader(),
          ),

          // 4. BOTTOM CAROUSEL
          if (_places.isNotEmpty && _activeRoute == null && !_isLoadingRoute && _showCarousel)
            Positioned(
              bottom: 90, left: 0, right: 0,
              height: 200,
              child: _buildBottomCarousel(),
            ),
        ],
      ),
    );
  }

  Widget _buildShaderIcon(IconData icon, {double size = 22, double stop = 0.3}) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: const [Color(0xFFD4FF59), Color(0xFFD4FF59), Color(0xFF1A6FDB), Color(0xFF1A6FDB)],
          stops: [0.0, stop, stop, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Abstract Shapes
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEFD),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -20,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: CurvePainterMap(),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peta Kampus',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0B132B), letterSpacing: -0.5),
                        ),
                        Text(
                          'Temukan layanan di kampus',
                          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.my_location_rounded, color: Color(0xFF1A6FDB), size: 22),
                        onPressed: () {
                          if (_currentPosition != null) {
                            _mapController.move(
                              LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16,
                            );
                          } else {
                            _loadLocation();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (value) {
                            _searchQuery = value;
                            _applySearch();
                          },
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Cari lokasi kampus...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w400),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16.0, right: 8.0),
                              child: Icon(Icons.search_rounded, color: Color(0xFF1A6FDB), size: 22),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (context) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: CategoryFilterWidget(
                              categories: _categories,
                              selectedCategoryId: _selectedCategoryId,
                              onCategorySelected: (id) {
                                _filterByCategory(id);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Center(
                          child: _buildShaderIcon(Icons.tune_rounded, size: 24, stop: 0.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircleButton(
          icon: Icons.my_location_rounded,
          onTap: () {
            if (_currentPosition != null) {
              _mapController.move(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16,
              );
            } else {
              _loadLocation();
            }
          },
        ),
        const SizedBox(height: 12),
        _buildCircleButton(
          text: '2D',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildCircleButton({IconData? icon, String? text, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: const Color(0xFF0B132B), size: 22)
              : Text(text!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF0B132B), fontSize: 15)),
        ),
      ),
    );
  }

  Widget _buildBottomCarousel() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _carouselController,
              onPageChanged: (idx) {
                setState(() => _selectedPlaceIndex = idx);
              },
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                final catName = _categoryMap[place.categoryId];
                final catIcon = AppTheme.getCategoryIcon(catName ?? '');

                String distanceText = '- m';
                if (_currentPosition != null) {
                  final m = DistanceHelper.calculateDistance(
                    startLat: _currentPosition!.latitude,
                    startLng: _currentPosition!.longitude,
                    endLat: place.latitude,
                    endLng: place.longitude,
                  );
                  distanceText = DistanceHelper.formatDistance(m);
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PlaceDetailScreen(place: place, categoryName: catName),
                    ));
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Image
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFF1F5F9),
                              image: place.photoUrl != null && place.photoUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(place.photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (place.photoUrl == null || place.photoUrl!.isEmpty)
                                ? const Center(child: Icon(Icons.image_rounded, color: Color(0xFF94A3B8), size: 32))
                                : null,
                          ),
                        ),
                        // Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, right: 16.0, left: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        place.name,
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0B132B), height: 1.2),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        await _favService.toggleFavorite(place.id);
                                      },
                                      child: Icon(
                                        _favService.favorites.value.contains(place.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: _favService.favorites.value.contains(place.id) ? const Color(0xFFEF4444) : const Color(0xFF0B132B),
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0B132B).withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(catIcon, size: 12, color: const Color(0xFF0B132B)),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                catName ?? '', 
                                                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF0B132B), fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        place.address,
                                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.near_me_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(distanceText, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 4),
                                    Text('${place.rating ?? 0.0}', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
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
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == 0 ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == 0 ? const Color(0xFF0B132B) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
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
              if (_showCarousel) {
                setState(() {
                  _showCarousel = false;
                });
              }
            },
          ),
          children: [
            // Tiles CartoDB Voyager for a clean, mapbox-like 3D feel
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
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
                final catIcon = AppTheme.getCategoryIcon(catName ?? '');
                final isActiveRoute = _activeRouteDest?.id == place.id;
                
                final isSelectedPlace = _selectedPlaceIndex == _places.indexOf(place) && _showCarousel;
                final isActive = isActiveRoute || isSelectedPlace;
                
                final bgColor = isActiveRoute ? const Color(0xFFD4FF59) : (isSelectedPlace ? const Color(0xFF1A6FDB) : const Color(0xFF0B132B));
                final iconColor = isActiveRoute ? const Color(0xFF0B132B) : (isSelectedPlace ? Colors.white : const Color(0xFFD4FF59));

                return Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: isActive ? 56 : 44,
                  height: isActive ? 60 : 50,
                  child: GestureDetector(
                    onTap: () {
                      final idx = _places.indexOf(place);
                      setState(() {
                        _showCarousel = true;
                        _selectedPlaceIndex = idx;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_carouselController.hasClients) {
                          _carouselController.jumpToPage(idx);
                        }
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: isActive ? 44 : 34,
                          height: isActive ? 44 : 34,
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isActive ? 3 : 2),
                            boxShadow: [
                              BoxShadow(
                                color: bgColor.withOpacity(0.45),
                                blurRadius: isActive ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isActiveRoute ? Icons.flag_rounded : catIcon,
                            color: iconColor,
                            size: isActive ? 22 : 17,
                          ),
                        ),
                        Container(
                          width: 2.5,
                          height: isActive ? 10 : 7,
                          decoration: BoxDecoration(
                            color: bgColor,
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A6FDB))),
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
              width: 48, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header tujuan
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catIcon, color: const Color(0xFF1A6FDB), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rute menuju', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                          Text(dest.name,
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0B132B)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Tombol tutup
                    GestureDetector(
                      onTap: _clearRoute,
                      child: Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats: jarak + waktu
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        icon: Icons.straighten_rounded,
                        color: const Color(0xFF1A6FDB),
                        label: route.formattedDistance,
                        sublabel: 'Jarak',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatChip(
                        icon: Icons.directions_walk_rounded,
                        color: const Color(0xFFD4FF59),
                        textColor: const Color(0xFF0B132B),
                        label: route.formattedDuration,
                        sublabel: 'Waktu',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Arah kompas
                if (bearing != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEFD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(_bearingToIcon(bearing), size: 24, color: const Color(0xFF1A6FDB)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menuju arah ${_bearingToLabel(bearing)}',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0B132B)),
                            ),
                            Text(
                              'Ikuti rute biru di peta',
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
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
    Color? textColor,
    required String label,
    required String sublabel,
  }) {
    final tColor = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: tColor)),
              Text(sublabel, style: GoogleFonts.poppins(fontSize: 11, color: tColor.withOpacity(0.8))),
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

class CurvePainterMap extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFFD4FF59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    var path = Path();
    
    canvas.drawCircle(const Offset(20, 20), 8, paint..style = PaintingStyle.fill);
    
    paint.style = PaintingStyle.stroke;
    path.moveTo(20, 20);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.8);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
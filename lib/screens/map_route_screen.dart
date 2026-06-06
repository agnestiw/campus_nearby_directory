import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import '../utils/distance_helper.dart';

/// Screen khusus yang langsung menampilkan rute dari lokasi user ke tempat tujuan.
/// Dipanggil dari PlaceDetailScreen saat user menekan "Buka Rute ke Sini".
class MapRouteScreen extends StatefulWidget {
  final PlaceModel destination;

  const MapRouteScreen({super.key, required this.destination});

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  RouteResult? _route;

  bool _isLoadingGps = true;
  bool _isLoadingRoute = false;
  String? _gpsError;

  // ── Design tokens ─────────────────────────────────────────────────────
  static const Color _primary    = Color(0xFF1A6FDB);
  static const Color _accent     = Color(0xFFD4FF59);   // lime-yellow
  static const Color _darkText   = Color(0xFF0B132B);
  static const Color _subtitle   = Color(0xFF64748B);
  static const Color _iconBg     = Color(0xFFE8EEFD);
  static const Color _pageBg     = Color(0xFFFAFAFC);

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  Future<void> _initRoute() async {
    // 1. Ambil GPS
    setState(() => _isLoadingGps = true);
    final result = await _locationService.getCurrentLocation();

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _isLoadingGps = false;
        _gpsError = _errorLabel(result.error!);
      });
      return;
    }

    final userLatLng = LatLng(result.position!.latitude, result.position!.longitude);
    setState(() {
      _userLocation = userLatLng;
      _isLoadingGps = false;
      _isLoadingRoute = true;
    });

    // 2. Fetch rute OSRM
    final destLatLng = LatLng(widget.destination.latitude, widget.destination.longitude);
    final route = await OsrmRoutingService.getRoute(origin: userLatLng, destination: destLatLng);

    if (!mounted) return;

    setState(() {
      _route = route;
      _isLoadingRoute = false;
    });

    if (route != null) {
      // Fit peta agar keduanya kelihatan
      final bounds = LatLngBounds.fromPoints([userLatLng, destLatLng]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.fromLTRB(40, 100, 40, 320)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil rute. Pastikan internet aktif.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _errorLabel(LocationError error) {
    switch (error) {
      case LocationError.serviceDisabled:
        return 'GPS tidak aktif. Aktifkan di pengaturan perangkat.';
      case LocationError.permissionDenied:
        return 'Izin lokasi ditolak.';
      case LocationError.permissionDeniedForever:
        return 'Izin lokasi ditolak permanen. Buka pengaturan.';
      case LocationError.unknown:
        return 'Gagal mendapatkan lokasi.';
    }
  }

  double _getBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final lat1R = lat1 * math.pi / 180;
    final lat2R = lat2 * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2R);
    final x = math.cos(lat1R) * math.sin(lat2R) -
        math.sin(lat1R) * math.cos(lat2R) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _bearingToLabel(double b) {
    if (b < 22.5 || b >= 337.5) return 'Utara';
    if (b < 67.5) return 'Timur Laut';
    if (b < 112.5) return 'Timur';
    if (b < 157.5) return 'Tenggara';
    if (b < 202.5) return 'Selatan';
    if (b < 247.5) return 'Barat Daya';
    if (b < 292.5) return 'Barat';
    return 'Barat Laut';
  }

  IconData _bearingToIcon(double b) {
    if (b < 22.5 || b >= 337.5) return Icons.arrow_upward_rounded;
    if (b < 67.5) return Icons.north_east_rounded;
    if (b < 112.5) return Icons.arrow_forward_rounded;
    if (b < 157.5) return Icons.south_east_rounded;
    if (b < 202.5) return Icons.arrow_downward_rounded;
    if (b < 247.5) return Icons.south_west_rounded;
    if (b < 292.5) return Icons.arrow_back_rounded;
    return Icons.north_west_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          dest.name,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: _darkText,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _darkText, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_userLocation != null)
            IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location_rounded, color: _primary, size: 18),
              ),
              tooltip: 'Lokasi Saya',
              onPressed: () {
                _mapController.move(_userLocation!, 16);
              },
            ),
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded, color: _primary, size: 18),
            ),
            tooltip: 'Hitung ulang rute',
            onPressed: _initRoute,
          ),
          const SizedBox(width: 4),
        ],
        // Lime accent bottom strip on AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _primary],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(dest),
    );
  }

  Widget _buildBody(PlaceModel dest) {
    if (_isLoadingGps) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mendapatkan lokasi GPS...',
              style: GoogleFonts.poppins(
                color: _subtitle,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_gpsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 44, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 20),
              Text(
                'GPS Tidak Tersedia',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _gpsError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _subtitle,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _initRoute,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    'Coba Lagi',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _locationService.openLocationSettings,
                  icon: const Icon(Icons.settings_rounded, size: 20),
                  label: Text(
                    'Buka Pengaturan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final destLatLng = LatLng(dest.latitude, dest.longitude);

    return Stack(
      children: [
        // ── PETA ──────────────────────────────────────
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? destLatLng,
              initialZoom: 15,
            ),
            children: [
              // Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_nearby_directory',
              ),

              // ── Polyline rute ────────────────────────
              if (_route != null)
                PolylineLayer(
                  polylines: [
                    // Glow outer
                    Polyline(
                      points: _route!.points,
                      strokeWidth: 14,
                      color: _primary.withValues(alpha: 0.15),
                    ),
                    // Glow inner
                    Polyline(
                      points: _route!.points,
                      strokeWidth: 8,
                      color: _primary.withValues(alpha: 0.25),
                    ),
                    // Garis utama
                    Polyline(
                      points: _route!.points,
                      strokeWidth: 5,
                      color: _primary,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              // ── Marker tujuan ────────────────────────
              MarkerLayer(
                markers: [
                  Marker(
                    point: destLatLng,
                    width: 56, height: 68,
                    child: Column(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_accent, _primary],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                        ),
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Marker user ──────────────────────────
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 60, height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.5),
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
        ),

        // ── Loading rute overlay ──────────────────────
        if (_isLoadingRoute)
          Positioned(
            top: 16, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Menghitung rute terbaik...',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Route info card ───────────────────────────
        if (_route != null && _userLocation != null)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildRouteInfoCard(dest),
          ),
      ],
    );
  }

  Widget _buildRouteInfoCard(PlaceModel dest) {
    final route = _route!;
    final bearing = _getBearing(
      _userLocation!.latitude, _userLocation!.longitude,
      dest.latitude, dest.longitude,
    );

    final straightDist = DistanceHelper.calculateDistance(
      startLat: _userLocation!.latitude,
      startLng: _userLocation!.longitude,
      endLat: dest.latitude,
      endLng: dest.longitude,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Lime accent strip ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Tujuan row ──────────────────────────────
                Row(
                  children: [
                    // White circle + border + ShaderMask icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _iconBg, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(child: _buildShaderIcon(Icons.flag_rounded)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tujuan',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _subtitle,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dest.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _darkText,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Stat boxes ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.route_rounded,
                        label: route.formattedDistance,
                        sublabel: 'Jarak jalan',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.directions_walk_rounded,
                        label: route.formattedDuration,
                        sublabel: 'Estimasi',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.straighten_rounded,
                        label: DistanceHelper.formatDistance(straightDist),
                        sublabel: 'Jarak lurus',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Compass row ─────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD0DFFA), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Compass icon — white circle + ShaderMask (shared helper)
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD0DFFA), width: 1),
                        ),
                        child: Center(
                          child: _buildShaderIcon(_bearingToIcon(bearing), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menuju ${_bearingToLabel(bearing)} (${bearing.round()}°)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _darkText,
                              ),
                            ),
                            Text(
                              'Ikuti garis biru di peta untuk navigasi',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _subtitle,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: _iconBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0DFFA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // White circle + ShaderMask icon (same as place_detail_screen)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD0DFFA), width: 1),
            ),
            child: Center(child: _buildShaderIcon(icon, size: 18)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _subtitle,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Lime-to-blue two-tone shader icon — identical to place_detail_screen & categories_screen
  Widget _buildShaderIcon(IconData icon, {double size = 22}) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent,   // lime (top-left portion)
            _accent,
            _primary,  // blue (rest)
            _primary,
          ],
          stops: [0.0, 0.35, 0.35, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
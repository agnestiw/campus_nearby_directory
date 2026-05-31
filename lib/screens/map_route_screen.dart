import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_theme.dart';
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
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.fromLTRB(40, 100, 40, 280)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil rute. Pastikan internet aktif.'),
            behavior: SnackBarBehavior.floating),
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
    final catColor = AppTheme.getCategoryColor('');
    final catIcon = AppTheme.getCategoryIcon('');

    return Scaffold(
      appBar: AppBar(
        title: Text(dest.name, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_userLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'Lokasi Saya',
              onPressed: () {
                _mapController.move(_userLocation!, 16);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Hitung ulang rute',
            onPressed: _initRoute,
          ),
        ],
      ),
      body: _buildBody(dest, catColor, catIcon),
    );
  }

  Widget _buildBody(PlaceModel dest, Color catColor, IconData catIcon) {
    if (_isLoadingGps) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mendapatkan lokasi GPS...', style: TextStyle(color: Color(0xFF6B7280))),
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
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 40, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 16),
              const Text('GPS Tidak Tersedia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text(_gpsError!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280), height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _initRoute,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6FDB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _locationService.openLocationSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Buka Pengaturan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A6FDB),
                    side: const BorderSide(color: Color(0xFF1A6FDB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
        FlutterMap(
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
                  // Glow
                  Polyline(
                    points: _route!.points,
                    strokeWidth: 12,
                    color: const Color(0xFF1A6FDB).withOpacity(0.18),
                  ),
                  // Garis utama
                  Polyline(
                    points: _route!.points,
                    strokeWidth: 5,
                    color: const Color(0xFF1A6FDB),
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
                  width: 56, height: 62,
                  child: Column(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.45),
                              blurRadius: 12, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                      ),
                      Container(width: 3, height: 10,
                          decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
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
                            color: const Color(0xFF1A6FDB).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 30, height: 30,
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
                            boxShadow: [BoxShadow(color: const Color(0xFF1A6FDB).withOpacity(0.5), blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A6FDB))),
                    SizedBox(width: 10),
                    Text('Menghitung rute terbaik...', style: TextStyle(fontSize: 13, color: Color(0xFF1A6FDB))),
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

    // Jarak lurus (straight-line)
    final straightDist = DistanceHelper.calculateDistance(
      startLat: _userLocation!.latitude,
      startLng: _userLocation!.longitude,
      endLat: dest.latitude,
      endLng: dest.longitude,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x28000000), blurRadius: 20, offset: Offset(0, -4))],
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
                // Tujuan label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tujuan', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          Text(dest.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Stats: jarak jalan + waktu + jarak lurus
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.route_rounded,
                        color: const Color(0xFF1A6FDB),
                        label: route.formattedDistance,
                        sublabel: 'Jarak jalan',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.directions_walk_rounded,
                        color: const Color(0xFF0F9E75),
                        label: route.formattedDuration,
                        sublabel: 'Estimasi',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.straighten_rounded,
                        color: const Color(0xFF8B5CF6),
                        label: DistanceHelper.formatDistance(straightDist),
                        sublabel: 'Jarak lurus',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Arah kompas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A6FDB).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_bearingToIcon(bearing), size: 20, color: const Color(0xFF1A6FDB)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Menuju ${_bearingToLabel(bearing)} (${bearing.round()}°)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                          const Text('Ikuti garis biru di peta untuk navigasi',
                            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
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

  Widget _buildStatBox({
    required IconData icon,
    required Color color,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          Text(sublabel, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
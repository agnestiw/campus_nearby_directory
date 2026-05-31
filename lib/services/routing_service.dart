import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/app_logger.dart';

class RouteResult {
  /// Daftar titik koordinat polyline jalan sungguhan
  final List<LatLng> points;

  /// Total jarak dalam meter
  final double distanceMeters;

  /// Estimasi waktu jalan kaki dalam detik
  final double durationSeconds;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '$hours jam $remaining menit';
  }
}

class OsrmRoutingService {
  // OSRM public API — gratis, tidak butuh API key
  // Menggunakan profil "foot" (jalan kaki) karena di sekitar kampus
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';
  static const String _profile = 'foot'; // foot | driving | cycling

  /// Ambil rute dari titik asal ke tujuan via OSRM
  static Future<RouteResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Format: longitude,latitude (OSRM pakai lon,lat — bukan lat,lon!)
      final originStr = '${origin.longitude},${origin.latitude}';
      final destStr = '${destination.longitude},${destination.latitude}';

      final uri = Uri.parse(
        '$_baseUrl/$_profile/$originStr;$destStr'
        '?overview=full&geometries=geojson&steps=false',
      );

      AppLogger.info('OSRM request: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        AppLogger.error('OSRM error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['code'] != 'Ok' || data['routes'] == null || (data['routes'] as List).isEmpty) {
        AppLogger.error('OSRM no route found');
        return null;
      }

      final route = data['routes'][0];
      final geometry = route['geometry'];
      final distanceMeters = (route['distance'] as num).toDouble();
      final durationSeconds = (route['duration'] as num).toDouble();

      // Decode GeoJSON coordinates array → List<LatLng>
      final coordinates = geometry['coordinates'] as List;
      final points = coordinates.map((coord) {
        // GeoJSON: [longitude, latitude]
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();

      AppLogger.success(
        'Route: ${points.length} pts, '
        '${(distanceMeters / 1000).toStringAsFixed(2)} km, '
        '${(durationSeconds / 60).round()} min',
      );

      return RouteResult(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      AppLogger.error('OSRM exception: $e');
      return null;
    }
  }
}
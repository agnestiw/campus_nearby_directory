import 'package:geolocator/geolocator.dart';

import '../core/app_logger.dart';

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationResult {
  final Position? position;
  final LocationError? error;

  LocationResult({this.position, this.error});

  bool get isSuccess => position != null;
}

class LocationService {
  // ─────────────────────────────────────
  // GET CURRENT LOCATION (one-time)
  // ─────────────────────────────────────
  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Cek apakah GPS service aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.error('GPS service disabled');
        return LocationResult(error: LocationError.serviceDisabled);
      }

      // 2. Cek permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        AppLogger.error('Location permission denied');
        return LocationResult(error: LocationError.permissionDenied);
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.error('Location permission denied forever');
        return LocationResult(error: LocationError.permissionDeniedForever);
      }

      // 3. Ambil posisi
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      AppLogger.success(
        'GPS: ${position.latitude}, ${position.longitude}',
      );

      return LocationResult(position: position);
    } catch (e) {
      AppLogger.error('GPS error: $e');
      return LocationResult(error: LocationError.unknown);
    }
  }

  // ─────────────────────────────────────
  // OPEN APP SETTINGS (for deniedForever)
  // ─────────────────────────────────────
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // ─────────────────────────────────────
  // OPEN LOCATION SETTINGS
  // ─────────────────────────────────────
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
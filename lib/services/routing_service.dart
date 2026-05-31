import 'package:url_launcher/url_launcher.dart';

import '../core/app_logger.dart';

class RoutingService {
  // ─────────────────────────────────────
  // BUKA RUTE KE TEMPAT TUJUAN
  // Menggunakan koordinat dari database
  // ─────────────────────────────────────
  static Future<bool> openRoute({
    required double destLat,
    required double destLng,
    String? destName,
  }) async {
    // Google Maps URL scheme — akan membuka aplikasi Google Maps
    // jika terinstall, atau browser jika tidak
    final encodedName = Uri.encodeComponent(destName ?? 'Tujuan');

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destLat,$destLng'
      '&destination_place_name=$encodedName'
      '&travelmode=walking',
    );

    // Fallback: geo URI (universal, semua navigation app)
    final geoUri = Uri.parse(
      'geo:$destLat,$destLng?q=$destLat,$destLng($encodedName)',
    );

    try {
      // Coba buka Google Maps dulu
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
        AppLogger.success('Opened Google Maps for routing');
        return true;
      }

      // Fallback ke geo URI
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
        AppLogger.success('Opened geo URI for routing');
        return true;
      }

      AppLogger.error('Cannot launch any map app');
      return false;
    } catch (e) {
      AppLogger.error('Routing error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────
  // BUKA WEBSITE TEMPAT
  // ─────────────────────────────────────
  static Future<bool> openWebsite(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Open website error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────
  // BUKA APLIKASI TELEPON
  // ─────────────────────────────────────
  static Future<bool> openPhone(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Open phone error: $e');
      return false;
    }
  }
}
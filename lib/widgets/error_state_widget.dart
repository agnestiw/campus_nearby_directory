import 'package:flutter/material.dart';

enum ErrorType {
  network,
  gpsDisabled,
  gpsPermission,
  gpsPermissionForever,
  empty,
  generic,
}

class ErrorStateWidget extends StatelessWidget {
  final ErrorType type;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onSettings;

  const ErrorStateWidget({
    super.key,
    required this.type,
    this.message,
    this.onRetry,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _iconBgColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: 40,
                color: _iconBgColor,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              _title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              message ?? _subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6FDB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

            if (onSettings != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Buka Pengaturan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A6FDB),
                    side: const BorderSide(color: Color(0xFF1A6FDB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.gpsDisabled:
        return Icons.location_off_rounded;
      case ErrorType.gpsPermission:
      case ErrorType.gpsPermissionForever:
        return Icons.location_disabled_rounded;
      case ErrorType.empty:
        return Icons.search_off_rounded;
      case ErrorType.generic:
        return Icons.error_outline_rounded;
    }
  }

  Color get _iconBgColor {
    switch (type) {
      case ErrorType.network:
        return const Color(0xFFEF4444);
      case ErrorType.gpsDisabled:
      case ErrorType.gpsPermission:
      case ErrorType.gpsPermissionForever:
        return const Color(0xFFF59E0B);
      case ErrorType.empty:
        return const Color(0xFF9CA3AF);
      case ErrorType.generic:
        return const Color(0xFFEF4444);
    }
  }

  String get _title {
    switch (type) {
      case ErrorType.network:
        return 'Tidak Ada Koneksi';
      case ErrorType.gpsDisabled:
        return 'GPS Tidak Aktif';
      case ErrorType.gpsPermission:
        return 'Izin Lokasi Diperlukan';
      case ErrorType.gpsPermissionForever:
        return 'Izin Lokasi Ditolak';
      case ErrorType.empty:
        return 'Tidak Ditemukan';
      case ErrorType.generic:
        return 'Terjadi Kesalahan';
    }
  }

  String get _subtitle {
    switch (type) {
      case ErrorType.network:
        return 'Periksa koneksi internet kamu dan coba lagi.';
      case ErrorType.gpsDisabled:
        return 'Aktifkan GPS di pengaturan perangkat untuk melihat jarak dan rute.';
      case ErrorType.gpsPermission:
        return 'Aplikasi membutuhkan izin lokasi untuk menampilkan jarak ke tempat tujuan.';
      case ErrorType.gpsPermissionForever:
        return 'Izin lokasi telah ditolak. Buka pengaturan aplikasi untuk mengaktifkannya.';
      case ErrorType.empty:
        return 'Tidak ada tempat yang cocok dengan pencarianmu. Coba kata kunci lain.';
      case ErrorType.generic:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
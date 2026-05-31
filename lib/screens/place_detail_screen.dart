import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/place_model.dart';

class PlaceDetailScreen extends StatelessWidget {
  final PlaceModel place;
  final String? categoryName;

  const PlaceDetailScreen({
    super.key,
    required this.place,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.getCategoryColor(categoryName ?? '');
    final catIcon = AppTheme.getCategoryIcon(categoryName ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // ── App Bar dengan foto ───────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: place.photoUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: catColor.withOpacity(0.1),
                      child: Center(child: Icon(catIcon, size: 60, color: catColor)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: catColor.withOpacity(0.1),
                      child: Center(child: Icon(catIcon, size: 60, color: catColor)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nama & badge ────────────────────────
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoryName != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(catIcon, size: 13, color: catColor),
                              const SizedBox(width: 5),
                              Text(categoryName!,
                                  style: TextStyle(color: catColor, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E), height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (place.rating != null)
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              final filled = i < place.rating!.floor();
                              final half = !filled && i < place.rating! && place.rating! - i >= 0.5;
                              return Icon(
                                half ? Icons.star_half_rounded
                                    : filled ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 20,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '${place.rating!.toStringAsFixed(1)} / 5.0',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Info tiles ──────────────────────────
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Alamat',
                        value: place.address,
                      ),
                      _buildDivider(),
                      _buildInfoTile(
                        icon: Icons.access_time_rounded,
                        iconColor: const Color(0xFF0F9E75),
                        title: 'Jam Operasional',
                        value: place.openHour ?? 'Tidak tersedia',
                      ),
                      if (place.phone != null) ...[
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.phone_rounded,
                          iconColor: const Color(0xFF1A6FDB),
                          title: 'Telepon',
                          value: place.phone!,
                        ),
                      ],
                      if (place.website != null) ...[
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Website',
                          value: place.website!,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Deskripsi ───────────────────────────
                if (place.description != null && place.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deskripsi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 10),
                        Text(place.description!,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.6)),
                      ],
                    ),
                  ),
                ],

                // ── Koordinat ───────────────────────────
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Koordinat',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      Text(
                        '${place.latitude.toStringAsFixed(6)}, ${place.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── Tombol Buka Rute (fixed bottom) ─────────────
      // Navigasi ke MapScreen dan langsung trigger routing
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              // Pop kembali ke halaman utama, lalu navigasi ke tab Map
              // dan kirimkan place yang dipilih untuk langsung routing
              Navigator.pop(context);
              // Gunakan callback via argument
              _openRouteOnMap(context, place);
            },
            icon: const Icon(Icons.directions_rounded, size: 22),
            label: const Text(
              'Buka Rute ke Sini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6FDB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  /// Navigasi ke MapScreen dan langsung tampilkan routing
  void _openRouteOnMap(BuildContext context, PlaceModel place) {
    Navigator.pushNamed(
      context,
      '/map-route',
      arguments: place,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFFF3F4F6));
  }
}
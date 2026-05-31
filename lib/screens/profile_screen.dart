import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // App logo
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6FDB),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A6FDB).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Campus Nearby Directory',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),

            const Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Aplikasi direktori berbasis peta untuk menemukan\ntempat di sekitar kampus.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Info cards
            _buildInfoCard(
              title: 'Mata Kuliah',
              value: 'Cloud Computing',
              icon: Icons.cloud_rounded,
              color: const Color(0xFF1A6FDB),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              title: 'Stack Teknologi',
              value: 'Flutter • Supabase • PostgreSQL\nOpenStreetMap • Geolocator',
              icon: Icons.developer_mode_rounded,
              color: const Color(0xFF8B5CF6),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              title: 'Sumber Data',
              value: 'Supabase (PostgreSQL)\nbrbyvcxhgoitgwrhfyfc.supabase.co',
              icon: Icons.storage_rounded,
              color: const Color(0xFF0F9E75),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              title: 'Map Provider',
              value: 'OpenStreetMap via flutter_map\n(Leaflet-based)',
              icon: Icons.map_rounded,
              color: const Color(0xFFF59E0B),
            ),

            const SizedBox(height: 32),

            const Text(
              'Dibuat untuk Project Cloud Computing',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
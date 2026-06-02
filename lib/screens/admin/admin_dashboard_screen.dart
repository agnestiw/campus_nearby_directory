import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_places_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDarkMode ? '🌙 Mode Gelap Aktif' : '☀️ Mode Terang Aktif'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari Admin Panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Logic logout sesungguhnya
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Berhasil keluar')),
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF);
    final cardColor = isDark ? const Color(0xFF1E2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2937);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode_rounded),
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card (Mirip gambar)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang, Admin 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kelola user & tempat dengan mudah',
                          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.admin_panel_settings_rounded, size: 60, color: Colors.white24),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Menu Utama',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),

            const SizedBox(height: 20),

            // Card Kelola User
            _buildModernCard(
              title: 'Kelola User',
              subtitle: 'Kelola akun pengguna',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              ),
            ),

            const SizedBox(height: 16),

            // Card Kelola Tempat
            _buildModernCard(
              title: 'Kelola Tempat',
              subtitle: 'Kelola data tempat & lokasi',
              icon: Icons.place_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPlacesScreen()),
              ),
            ),

            const SizedBox(height: 40),

            // Stats Section (Tambahan agar mirip gambar)
            Text(
              'Ringkasan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total User', '248', Icons.people, const Color(0xFF6366F1), isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Total Tempat', '87', Icons.place, const Color(0xFF10B981), isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardColor = isDark ? const Color(0xFF1E2937) : Colors.white;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 42, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 6,
      color: isDark ? const Color(0xFF1E2937) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E2937),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_places_screen.dart';
import 'admin_users_screen.dart';
import '../../screens/auth/login_screen.dart';   // ← Tambahan import

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
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
              
              // Tambahan: Langsung ke halaman Login dan hapus semua route sebelumnya
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
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
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2937);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Dashboard Admin', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22)),
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
            // Welcome Section - Lebih Premium
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang Kembali 👋',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Admin Panel • Campus Nearby',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard('Total User', '1.248', '↑ 12%', Icons.people_alt_rounded, const Color(0xFF10B981), isDark),
                _buildStatCard('Total Tempat', '342', '↑ 8%', Icons.place_rounded, const Color(0xFF6366F1), isDark),
                _buildStatCard('Aktif Hari Ini', '87', '↓ 3%', Icons.access_time, const Color(0xFFEF4444), isDark),
                _buildStatCard('Pending Review', '24', '↑ 5%', Icons.pending_actions, const Color(0xFFF59E0B), isDark),
              ],
            ),

            const SizedBox(height: 40),

            // Menu Utama
            Text(
              'Menu Utama',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            _buildModernCard(
              title: 'Kelola User',
              subtitle: 'Kelola akun & hak akses pengguna',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
            ),

            const SizedBox(height: 16),

            _buildModernCard(
              title: 'Kelola Tempat',
              subtitle: 'Data tempat wisata & lokasi kampus',
              icon: Icons.place_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPlacesScreen())),
            ),

            const SizedBox(height: 40),

            // Recent Activity
            Text(
              'Aktivitas Terbaru',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(isDark),
          ],
        ),
      ),
    );
  }

  // Stat Card dengan desain lebih modern
  Widget _buildStatCard(String title, String value, String change, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2937) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E2937),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: TextStyle(
              color: change.contains('↑') ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Card
  Widget _buildModernCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2937) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E2937))),
                      const SizedBox(height: 6),
                      Text(subtitle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.4)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Recent Activity yang lebih cantik
  Widget _buildRecentActivity(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2937) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF3B82F6),
                child: Icon(Icons.person_add, color: Colors.white),
              ),
              title: const Text('User baru mendaftar'),
              subtitle: const Text('12 orang hari ini'),
              trailing: const Chip(
                label: Text('Baru', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.green,
              ),
            ),
            const Divider(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF59E0B),
                child: Icon(Icons.place, color: Colors.white),
              ),
              title: const Text('Tempat baru ditambahkan'),
              subtitle: const Text('Pantai Indah Baru'),
              trailing: const Chip(
                label: Text('Pending', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
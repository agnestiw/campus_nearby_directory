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
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    // TODO: Integrasikan dengan ThemeProvider nanti untuk mengubah tema global
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDarkMode ? '🌙 Mode Gelap Diaktifkan' : '☀️ Mode Terang Diaktifkan'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Tambahkan logic logout (clear session, navigate to login)
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
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2937);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : null,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Theme Switch Button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _toggleTheme,
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sambutan Admin dengan Blue Theme
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang, Admin 👋',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola sistem dengan mudah dan aman',
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.85)),
                  ),
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
            _buildMenuCard(
              context,
              title: 'Kelola User',
              subtitle: 'Kelola akun pengguna',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // Card Kelola Tempat
            _buildMenuCard(
              context,
              title: 'Kelola Tempat',
              subtitle: 'Kelola data tempat dan lokasi',
              icon: Icons.place_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPlacesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardColor = isDark ? const Color(0xFF1E2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2937);

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.grey[400] : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
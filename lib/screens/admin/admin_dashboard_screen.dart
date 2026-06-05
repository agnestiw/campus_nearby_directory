import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../main.dart';
import '../../models/profile_model.dart';
import '../../models/place_model.dart';
import '../../services/user_service.dart';
import '../../services/place_service.dart';
import '../../services/category_service.dart';
import '../../widgets/error_state_widget.dart';

import 'admin_places_screen.dart';
import 'admin_users_screen.dart';
import 'admin_categories_screen.dart';
import '../../screens/auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserService _userService = UserService();
  final PlaceService _placeService = PlaceService();
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = true;
  String? _error;
  int _userCount = 0;
  int _placeCount = 0;
  int _categoryCount = 0;
  List<ProfileModel> _recentUsers = [];
  List<PlaceModel> _recentPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _userService.countUsers();
      final places = await _placeService.countPlaces();
      final categories = await _categoryService.countCategories();
      final recentUsers = await _userService.getRecentUsers(limit: 2);
      final recentPlaces = await _placeService.getRecentPlaces(limit: 2);
      if (!mounted) return;
      setState(() {
        _userCount = users;
        _placeCount = places;
        _categoryCount = categories;
        _recentUsers = recentUsers;
        _recentPlaces = recentPlaces;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  void _toggleTheme() {
    MyApp.of(context)?.toggleTheme();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari Admin Panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              'Keluar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorStateWidget(type: ErrorType.network, onRetry: _loadDashboardData)
                : Stack(
                    children: [
                      // Background Abstract Shapes
                      Positioned(
                        top: -60,
                        left: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF1E293B).withOpacity(0.3)
                                : const Color(0xFFE8EEFD),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        right: 0,
                        child: CustomPaint(
                          size: const Size(120, 150),
                          painter: CurvePainter(),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ──────────────────────────────────────────────────
                            _buildHeader(theme, colorScheme),
                            const SizedBox(height: 20),

                            // ── Welcome Banner ───────────────────────────────────────────
                            _buildWelcomeBanner(theme),
                            const SizedBox(height: 24),

                            // ── Statistik ────────────────────────────────────────────────
                            _buildSectionLabel(theme, 'Statistik', 'Ringkasan'),
                            const SizedBox(height: 12),
                            _buildStatsGrid(theme, colorScheme),
                            const SizedBox(height: 24),

                            // ── Menu Utama ───────────────────────────────────────────────
                            _buildSectionLabel(theme, 'Menu Utama', null),
                            const SizedBox(height: 12),
                            _buildMenuCard(
                              theme: theme,
                              title: 'Kelola User',
                              subtitle: 'Kelola akun & hak akses pengguna',
                              icon: Icons.people_alt_rounded,
                              accentColor: colorScheme.primary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                              ).then((_) => _loadDashboardData()),
                            ),
                            const SizedBox(height: 12),
                            _buildMenuCard(
                              theme: theme,
                              title: 'Kelola Tempat',
                              subtitle: 'Data tempat wisata & lokasi kampus',
                              icon: Icons.place_rounded,
                              accentColor: colorScheme.secondary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminPlacesScreen()),
                              ).then((_) => _loadDashboardData()),
                            ),
                            const SizedBox(height: 12),
                            _buildMenuCard(
                              theme: theme,
                              title: 'Kelola Kategori',
                              subtitle: 'Manajemen kategori tempat',
                              icon: Icons.category_rounded,
                              accentColor: AppTheme.warning,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
                              ).then((_) => _loadDashboardData()),
                            ),
                            const SizedBox(height: 24),

                            // ── Aktivitas Terbaru ────────────────────────────────────────
                            _buildSectionLabel(theme, 'Aktivitas Terbaru', null),
                            const SizedBox(height: 12),
                            _buildRecentActivity(theme, colorScheme),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Admin',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola direktori tempat dan user kampus',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        // Toggle dark/light
        Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: theme.brightness == Brightness.dark ? 'Mode Terang' : 'Mode Gelap',
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.brightness == Brightness.dark ? const Color(0xFFD4FF59) : const Color(0xFF1A6FDB),
            ),
            onPressed: _toggleTheme,
          ),
        ),
        const SizedBox(width: 8),
        // Logout
        Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Keluar',
            icon: Icon(Icons.logout_rounded, color: cs.error),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Welcome Banner
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Dark Slate
            Color(0xFF1A6FDB), // Vibrant Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6FDB).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Admin • Campus Nearby',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section Label
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(ThemeData theme, String title, String? trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stats Grid
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(ThemeData theme, ColorScheme cs) {
    final stats = [
      _StatItem('Total User', '$_userCount', '', Icons.people_alt_rounded, cs.primary),
      _StatItem('Total Tempat', '$_placeCount', '', Icons.place_rounded, cs.secondary),
      _StatItem('Total Kategori', '$_categoryCount', '', Icons.category_rounded, AppTheme.warning),
      _StatItem('Aktivitas Terbaru', '${_recentUsers.length + _recentPlaces.length}', '', Icons.access_time_rounded, cs.error),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (_, i) => _buildStatCard(theme, stats[i]),
    );
  }

  Widget _buildStatCard(ThemeData theme, _StatItem item) {
    final isPositive = item.change.contains('↑');
    final changeColor = isPositive
        ? const Color(0xFF22C55E)
        : theme.colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE8EEFD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 22, color: item.color),
          ),
          const SizedBox(height: 10),
          // Value
          Text(
            item.value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 2),
          // Title
          Text(
            item.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.change.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.change,
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Menu Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMenuCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE8EEFD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left Icon Container (bordered + dual gradient shader mask)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE8EEFD),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFD4FF59),
                            Color(0xFFD4FF59),
                            Color(0xFF1A6FDB),
                            Color(0xFF1A6FDB)
                          ],
                          stops: [0.0, 0.35, 0.35, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Center details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right Arrow Action Button (lime-green round)
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4FF59),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF0B132B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Recent Activity
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRecentActivity(ThemeData theme, ColorScheme cs) {
    final activityTiles = <Widget>[];
    activityTiles.addAll(_recentUsers.map(
      (user) => _buildActivityTile(
        theme: theme,
        icon: Icons.person_add_rounded,
        avatarColor: cs.secondary,
        title: user.fullName,
        subtitle: user.email,
        badge: user.roleName,
        badgeColor: cs.secondary,
      ),
    ));
    activityTiles.addAll(_recentPlaces.map(
      (place) => _buildActivityTile(
        theme: theme,
        icon: Icons.place_rounded,
        avatarColor: AppTheme.warning,
        title: place.name,
        subtitle: place.address,
        badge: 'Tempat',
        badgeColor: AppTheme.warning,
      ),
    ));

    if (activityTiles.isEmpty) {
      activityTiles.add(
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text('Belum ada aktivitas terbaru', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE8EEFD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (var i = 0; i < activityTiles.length; i++) ...[
              activityTiles[i],
              if (i < activityTiles.length - 1) Divider(height: 1, color: theme.dividerColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile({
    required ThemeData theme,
    required IconData icon,
    required Color avatarColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: avatarColor.withOpacity(0.12),
        radius: 20,
        child: Icon(icon, color: avatarColor, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF64748B),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          badge,
          style: TextStyle(
            color: badgeColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Curve Painter untuk ornamen lengkungan neon
// ─────────────────────────────────────────────────────────────────────────────
class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFFD4FF59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    var path = Path();
    
    // Start with a small circle
    canvas.drawCircle(const Offset(20, 20), 8, paint..style = PaintingStyle.fill);
    
    // Draw the curve
    paint.style = PaintingStyle.stroke;
    path.moveTo(20, 20);
    path.quadraticBezierTo(size.width * 0.7, 10, size.width, size.height);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model kecil untuk stat card
// ─────────────────────────────────────────────────────────────────────────────
class _StatItem {
  const _StatItem(this.title, this.value, this.change, this.icon, this.color);
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
}
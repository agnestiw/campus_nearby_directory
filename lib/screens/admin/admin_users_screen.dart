import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../models/profile_model.dart';
import '../../services/user_service.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_user_form_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();
  List<ProfileModel> _users = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _userService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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

  List<ProfileModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus User',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus user ini?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(
                color: AppTheme.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final deleted = await _userService.deleteUser(userId);
      if (!deleted) throw Exception('Penghapusan user gagal');
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ User berhasil dihapus',
                style: GoogleFonts.poppins(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menghapus: $e',
                style: GoogleFonts.poppins(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openForm({ProfileModel? user, required UserFormMode mode}) async {
    final changed = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserFormScreen(mode: mode, user: user),
      ),
    );
    if (changed == true) await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [
          // ── Dekorasi pojok kiri atas — sama dengan CategoriesScreen ──────
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEFD),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // ── Dekorasi garis kuning kanan atas ─────────────────────────────
          Positioned(
            top: 50,
            right: 0,
            child: CustomPaint(
              size: const Size(120, 150),
              painter: _CurvePainter(),
            ),
          ),

          // ── Konten utama ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tombol back bulat putih — persis CategoriesScreen
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF0B132B),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Judul besar — DNA CategoriesScreen
                      Text(
                        'Kelola User',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B132B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola akun & hak akses pengguna',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0B132B).withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Search bar pill — sama persis CategoriesScreen
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau email...',
                            hintStyle: GoogleFonts.poppins(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Padding(
                              padding:
                                  EdgeInsets.only(left: 20, right: 12),
                              child: Icon(Icons.search,
                                  color: Color(0xFF1A6FDB), size: 22),
                            ),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 50),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Counter
                      if (!_isLoading && _error == null)
                        Text(
                          '${_filteredUsers.length} pengguna ditemukan',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // ── List ────────────────────────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? ErrorStateWidget(
                              type: ErrorType.network,
                              onRetry: _loadUsers,
                            )
                          : _filteredUsers.isEmpty
                              ? _buildEmpty()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      24, 0, 24, 100),
                                  itemCount: _filteredUsers.length,
                                  itemBuilder: (_, i) {
                                    final user = _filteredUsers[i];
                                    return _UserCard(
                                      user: user,
                                      onDelete: () => _deleteUser(user.id),
                                      onEdit: () => _openForm(
                                          user: user,
                                          mode: UserFormMode.edit),
                                      onView: () => _openForm(
                                          user: user,
                                          mode: UserFormMode.view),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),

          // ── FAB kuning — konsisten dengan accent CategoriesScreen ─────────
          Positioned(
            bottom: 24,
            right: 24,
            child: GestureDetector(
              onTap: () => _openForm(mode: UserFormMode.create),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4FF59),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4FF59).withOpacity(0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF0B132B),
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 36,
              color: Color(0xFF1A6FDB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada user ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci yang berbeda',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Card
// DNA card dari CategoriesScreen:
//   • borderRadius: 24
//   • shadow: opacity 0.03, blurRadius 10
//   • padding: 16
//   • icon container 56×56, borderRadius 16, border tipis
// Tombol aksi tetap vertikal (tidak overflow) tapi diberi border circle
// agar konsisten dengan gaya tombol bulat di CategoriesScreen
// ─────────────────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
  });

  final ProfileModel user;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;

  // Warna avatar variatif berdasar huruf awal
  static const List<Color> _palette = [
    Color(0xFF1A6FDB),
    Color(0xFF0F9E75),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
  ];

  Color get _avatarColor {
    if (user.fullName.isEmpty) return _palette[0];
    return _palette[user.fullName.codeUnitAt(0) % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.roleName.toLowerCase() == 'admin';
    final initial =
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';
    final ac = _avatarColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar — kotak rounded (sama dengan icon container di CategoriesScreen)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ac.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ac.withOpacity(0.22),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ac,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Info ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + badge Admin
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B132B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Admin',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  user.email,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),

                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Role: ${user.roleName[0].toUpperCase()}${user.roleName.substring(1)}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A6FDB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Tombol aksi vertikal ──────────────────────────────────────────
          // Menggunakan lingkaran kecil agar konsisten dengan gaya bulat
          // CategoriesScreen. Ukuran 32×32 agar tidak overflow.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionCircle(
                icon: Icons.visibility_rounded,
                color: const Color(0xFF1A6FDB),
                bg: const Color(0xFFE8EEFD),
                onTap: onView,
                tooltip: 'Lihat',
              ),
              const SizedBox(height: 6),
              _ActionCircle(
                icon: Icons.edit_rounded,
                color: const Color(0xFF0F9E75),
                bg: const Color(0xFFD1FAE5),
                onTap: onEdit,
                tooltip: 'Edit',
              ),
              const SizedBox(height: 6),
              _ActionCircle(
                icon: Icons.delete_rounded,
                color: AppTheme.danger,
                bg: const Color(0xFFFFE4E4),
                onTap: onDelete,
                tooltip: 'Hapus',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tombol bulat kecil — konsisten dengan arrow circle di CategoriesScreen
// ─────────────────────────────────────────────────────────────────────────────
class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CurvePainter — copy persis dari CategoriesScreen
// ─────────────────────────────────────────────────────────────────────────────
class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4FF59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      const Offset(20, 20),
      8,
      paint..style = PaintingStyle.fill,
    );

    paint.style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(20, 20)
      ..quadraticBezierTo(size.width * 0.7, 10, size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
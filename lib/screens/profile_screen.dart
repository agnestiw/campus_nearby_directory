import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  String _name = 'Memuat...';
  String _email = 'memuat...';
  String? _phone;
  String? _profilePhotoUrl;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _authService.currentUserId;
    final email = _authService.currentUserEmail;

    if (userId != null) {
      final profile = await _authService.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _name = profile?.fullName ?? 'User Tanpa Nama';
          _email = email ?? 'Email tidak ditemukan';
          _phone = profile?.phone;
          _profilePhotoUrl = profile?.profilePhoto;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      debugPrint('[PICK IMAGE] Starting image picker');

      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile == null) {
        debugPrint('[PICK IMAGE] User cancelled image picker');
        return;
      }

      debugPrint('[PICK IMAGE] Image picked: ${pickedFile.path}');

      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);

      final userId = _authService.currentUserId;
      if (userId == null) {
        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal: User ID tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('[PICK IMAGE] User ID: $userId');

      // Read bytes directly from XFile (works on web, android, iOS)
      final bytes = await pickedFile.readAsBytes();

      // Upload photo ke Supabase Storage
      final photoUrl = await _authService.uploadProfilePhoto(
        userId: userId,
        fileBytes: bytes,
      );

      if (!mounted) return;

      if (photoUrl != null) {
        debugPrint(
          '[PICK IMAGE] Photo uploaded successfully, updating database',
        );

        // Update profile photo URL di database
        final success = await _authService.updateProfilePhotoUrl(
          userId: userId,
          photoUrl: photoUrl,
        );

        if (!mounted) return;

        if (success) {
          setState(() {
            _profilePhotoUrl = photoUrl;
            _isUploadingPhoto = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto profil berhasil diperbarui!'),
              backgroundColor: AppTheme.accent,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => _isUploadingPhoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Foto terupload tapi gagal menyimpan ke database.',
              ),
              backgroundColor: AppTheme.warning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isUploadingPhoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunggah foto. Silakan coba lagi.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[PICK IMAGE ERROR]');
      debugPrint('Exception: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone ?? '');
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EFFA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Profil',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: isUpdating
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Perbarui informasi akun Anda dengan cepat dan aman.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        labelStyle: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      enabled: !isUpdating,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        labelStyle: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        hintText: '+62...',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      enabled: !isUpdating,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: TextEditingController(text: _email),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F5FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isUpdating
                          ? null
                          : () async {
                              final userId = _authService.currentUserId;
                              if (userId == null) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Gagal: User ID tidak ditemukan',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => isUpdating = true);

                              final success = await _authService
                                  .updateUserProfile(
                                    userId: userId,
                                    fullName: nameController.text.trim(),
                                    phone: phoneController.text.trim().isEmpty
                                        ? null
                                        : phoneController.text.trim(),
                                  );

                              if (!mounted) return;

                              if (success) {
                                this.setState(() {
                                  _name = nameController.text.trim();
                                  _phone = phoneController.text.trim().isEmpty
                                      ? null
                                      : phoneController.text.trim();
                                });

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Profil berhasil diperbarui!',
                                    ),
                                    backgroundColor: AppTheme.accent,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Gagal memperbarui profil. Silakan coba lagi.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() => isUpdating = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isUpdating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDummySettingsDialog() {
    final theme = Theme.of(context);
    bool isDarkMode = false;
    bool isNotificationsEnabled = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EFFA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Preferensi Aplikasi',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Atur preferensi dasar untuk tampilan aplikasi dan notifikasi.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Notifikasi',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Aktifkan pemberitahuan terbaru',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: isNotificationsEnabled,
                            activeColor: AppTheme.primary,
                            onChanged: (val) =>
                                setState(() => isNotificationsEnabled = val),
                          ),
                          const Divider(height: 1, color: Color(0xFFE9EFFA)),
                          SwitchListTile(
                            title: Text(
                              'Mode Gelap',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Gunakan tampilan gelap pada aplikasi',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: isDarkMode,
                            activeColor: AppTheme.primary,
                            onChanged: (val) =>
                                setState(() => isDarkMode = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSettingsOption(
                      title: 'Bahasa',
                      subtitle: 'Indonesia',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsOption(
                      title: 'Kebijakan Privasi',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDummyHelpDialog() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EFFA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pusat Bantuan',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Temukan jawaban cepat untuk masalah umum profil Anda.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildHelpTile(
                  title: 'Bagaimana cara upload foto profil?',
                  description:
                      'Klik ikon kamera di sudut kanan bawah foto profil Anda, lalu pilih foto dari galeri. Pastikan ukuran foto tidak terlalu besar.',
                ),
                const SizedBox(height: 12),
                _buildHelpTile(
                  title: 'Kenapa email tidak bisa diganti?',
                  description:
                      'Email Anda terikat langsung dengan akun utama untuk keamanan dan pemulihan kata sandi.',
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Hubungi Customer Service',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsOption({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7C84A3)),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile({required String title, required String description}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        collapsedIconColor: AppTheme.primary,
        iconColor: AppTheme.primary,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF0B132B),
          ),
        ),
        children: [
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;

    // Navigasi ke halaman Login dan hapus seluruh stack halaman sebelumnya
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [
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
          Positioned(
            top: 50,
            right: 0,
            child: Container(
              width: 120,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF2FE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(100),
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B132B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola akun dan informasi pribadi Anda',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0B132B).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: _profilePhotoUrl != null
                                      ? NetworkImage(_profilePhotoUrl!)
                                      : const AssetImage(
                                              'assets/images/profile.jpg',
                                            )
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: _isUploadingPhoto
                                  ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto
                                    ? null
                                    : _pickAndUploadPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.photo_camera_rounded,
                                    color: Colors.white.withOpacity(
                                      _isUploadingPhoto ? 0.5 : 1.0,
                                    ),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _name,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B132B),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _email,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: const Color(0xFF0B132B).withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _phone ?? 'Nomor telepon belum diatur',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Pengaturan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListItem(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          iconColor: AppTheme.primary,
                          title: 'Edit Profil',
                          subtitle: 'Ubah data diri Anda',
                          onTap: _showEditProfileDialog,
                        ),
                        Divider(
                          height: 1,
                          color: theme.dividerColor.withOpacity(0.3),
                          indent: 72,
                          endIndent: 24,
                        ),
                        _buildListItem(
                          context: context,
                          icon: Icons.settings_outlined,
                          iconColor: AppTheme.primary,
                          title: 'Preferensi',
                          subtitle: 'App & Privasi',
                          onTap: _showDummySettingsDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lainnya',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListItem(
                          context: context,
                          icon: Icons.help_outline_rounded,
                          iconColor: AppTheme.primary,
                          title: 'Bantuan',
                          subtitle: 'FAQ & Customer Service',
                          onTap: _showDummyHelpDialog,
                        ),
                        Divider(
                          height: 1,
                          color: theme.dividerColor.withOpacity(0.3),
                          indent: 72,
                          endIndent: 24,
                        ),
                        _buildListItem(
                          context: context,
                          icon: Icons.logout_rounded,
                          iconColor: AppTheme.primary,
                          title: 'Keluar',
                          subtitle: 'Akhiri sesi Anda',
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Versi Aplikasi 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      width: 14,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4FF59),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFD4FF59),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF0B132B),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

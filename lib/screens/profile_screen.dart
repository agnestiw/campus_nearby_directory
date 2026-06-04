import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
        debugPrint('[PICK IMAGE] Photo uploaded successfully, updating database');
        
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
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: Color(0xFF34A853),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => _isUploadingPhoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto terupload tapi gagal menyimpan ke database.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
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
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone ?? '');
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Profil', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isUpdating,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(),
                      hintText: '+62...',
                    ),
                    enabled: !isUpdating,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: _email),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false,
                  ),
                  if (isUpdating)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A6FDB)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Menyimpan...',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A6FDB)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(context),
                  child: Text('Batal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          final userId = _authService.currentUserId;
                          if (userId == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gagal: User ID tidak ditemukan')),
                            );
                            return;
                          }

                          setState(() => isUpdating = true);

                          final success = await _authService.updateUserProfile(
                            userId: userId,
                            fullName: nameController.text.trim(),
                            phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          );

                          if (!mounted) return;

                          if (success) {
                            // Update local state
                            this.setState(() {
                              _name = nameController.text.trim();
                              _phone = phoneController.text.trim().isEmpty ? null : phoneController.text.trim();
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil berhasil diperbarui!'),
                                backgroundColor: Color(0xFF34A853),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal memperbarui profil. Silakan coba lagi.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => isUpdating = false);
                          }
                        },
                  child: Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDummySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pengaturan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Ini adalah halaman pengaturan (Dummy). Fitur ini belum terhubung dengan backend.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDummyHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pusat Bantuan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Silakan hubungi admin@kampus.edu untuk bantuan lebih lanjut mengenai aplikasi ini.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A6FDB)))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vibrant Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FC), // Pastel Blue
                borderRadius: BorderRadius.circular(36),
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
                              color: const Color(0xFF1A6FDB).withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: DecorationImage(
                            image: _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!)
                                : const AssetImage('assets/images/profile.jpg') as ImageProvider,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white.withOpacity(_isUploadingPhoto ? 0.5 : 1.0),
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
                      color: const Color(0xFF1A1A2E),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _email,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bento Grid for Options
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    title: 'Edit Profil',
                    subtitle: 'Ubah Data',
                    icon: Icons.person_outline_rounded,
                    backgroundColor: const Color(0xFFFFE5E5), // Pastel Pink/Red
                    iconColor: const Color(0xFFE85D5D),
                    onTap: _showEditProfileDialog,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBentoCard(
                    title: 'Pengaturan',
                    subtitle: 'App & Privasi',
                    icon: Icons.settings_outlined,
                    backgroundColor: const Color(0xFFEAE5FF), // Pastel Purple
                    iconColor: const Color(0xFF7A5DC8),
                    onTap: _showDummySettingsDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    title: 'Bantuan',
                    subtitle: 'FAQ & CS',
                    icon: Icons.help_outline_rounded,
                    backgroundColor: const Color(0xFFFFF4D4), // Pastel Yellow
                    iconColor: const Color(0xFFD49900),
                    onTap: _showDummyHelpDialog,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBentoCard(
                    title: 'Keluar',
                    subtitle: 'Akhiri Sesi',
                    icon: Icons.logout_rounded,
                    backgroundColor: const Color(0xFFE5F8ED), // Pastel Green
                    iconColor: const Color(0xFF34A853),
                    onTap: _handleLogout,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            Text(
              'Versi Aplikasi 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
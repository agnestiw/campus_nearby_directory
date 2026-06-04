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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profil',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                        onPressed: isUpdating ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A6FDB), width: 2),
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
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      hintText: '+62...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A6FDB), width: 2),
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
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6FDB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Simpan Perubahan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDummySettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isDarkMode = false;
        bool isNotificationsEnabled = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(top: 24, bottom: MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Preferensi Aplikasi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.withOpacity(0.1), thickness: 1),
                  SwitchListTile(
                    title: Text('Notifikasi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('Izinkan pop-up info', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    value: isNotificationsEnabled,
                    activeColor: const Color(0xFF1A6FDB),
                    onChanged: (val) => setState(() => isNotificationsEnabled = val),
                  ),
                  SwitchListTile(
                    title: Text('Mode Gelap', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('Tampilan layar gelap', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    value: isDarkMode,
                    activeColor: const Color(0xFF1A6FDB),
                    onChanged: (val) => setState(() => isDarkMode = val),
                  ),
                  ListTile(
                    title: Text('Bahasa', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('Indonesia', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A6FDB))),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text('Kebijakan Privasi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () {},
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDummyHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: 24, bottom: MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pusat Bantuan',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey.withOpacity(0.1), thickness: 1),
              ExpansionTile(
                title: Text('Bagaimana cara upload foto profil?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                children: [
                  Text(
                    'Klik ikon kamera di sudut kanan bawah foto profil Anda, lalu pilih foto dari galeri. Pastikan ukuran foto tidak terlalu besar.',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Kenapa email tidak bisa diganti?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                children: [
                  Text(
                    'Email Anda terikat langsung dengan akun utama untuk keamanan dan pemulihan kata sandi.',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5F8ED),
                    foregroundColor: const Color(0xFF34A853),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text('Hubungi Customer Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
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
      backgroundColor: const Color(0xFFF5F7FA), // Very soft grey/blue background
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
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
            // Vibrant Profile Header (Centered)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FC), // Pastel Blue
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A6FDB).withOpacity(0.08),
                    blurRadius: 24,
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
                              color: const Color(0xFF1A1A2E), // Dark background for contrast
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
                  const SizedBox(height: 6),
                  Text(
                    _phone ?? 'Nomor telepon belum diatur',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF1A6FDB),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings List - Neat but lively icons
            Text(
              'Pengaturan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
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
                    icon: Icons.person_outline_rounded,
                    iconBgColor: const Color(0xFFE8F1FC),
                    iconColor: const Color(0xFF1A6FDB),
                    title: 'Edit Profil',
                    subtitle: 'Ubah data diri Anda',
                    onTap: _showEditProfileDialog,
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 72, endIndent: 24),
                  _buildListItem(
                    icon: Icons.settings_outlined,
                    iconBgColor: const Color(0xFFEAE5FF),
                    iconColor: const Color(0xFF7A5DC8),
                    title: 'Preferensi',
                    subtitle: 'App & Privasi (Dummy)',
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
                color: const Color(0xFF1A1A2E),
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
                    icon: Icons.help_outline_rounded,
                    iconBgColor: const Color(0xFFFFF4D4),
                    iconColor: const Color(0xFFD49900),
                    title: 'Bantuan',
                    subtitle: 'FAQ & Customer Service',
                    onTap: _showDummyHelpDialog,
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 72, endIndent: 24),
                  _buildListItem(
                    icon: Icons.logout_rounded,
                    iconBgColor: const Color(0xFFFFE5E5),
                    iconColor: const Color(0xFFE85D5D),
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

  Widget _buildListItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
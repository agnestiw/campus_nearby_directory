import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/auth_service.dart';
import '../../../navigation/main_navigation.dart';
import '../admin/admin_dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Memberikan sedikit delay agar transisi mulus
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = _authService.currentSession;
    final userId = _authService.currentUserId;

    if (session != null && userId != null) {
      // Jika ada session aktif, cek role user
      final profile = await _authService.getUserProfile(userId);
      
      if (!mounted) return;

      if (profile != null && profile.roleName == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        // Default arahkan ke halaman utama pengguna (user)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } else {
      // Jika tidak ada session, arahkan ke Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 80,
              color: const Color(0xFF1A6FDB),
            ),
            const SizedBox(height: 16),
            Text(
              'Campus Directory',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFF1A6FDB),
            ),
          ],
        ),
      ),
    );
  }
}
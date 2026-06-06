import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey                  = GlobalKey<FormState>();
  final _nameController           = TextEditingController();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService  = AuthService();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading              = false;

  // ── Design tokens (same as login) ────────────────────────────
  static const _primary  = Color(0xFF1A6FDB);
  static const _accent   = Color(0xFFD4FF59);
  static const _dark     = Color(0xFF0B132B);
  static const _iconBg   = Color(0xFFE8EEFD);
  static const _subtitle = Color(0xFF64748B);
  static const _border   = Color(0xFFE2E8F0);

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi berhasil! Silakan login.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          backgroundColor: const Color(0xFF0F9E75),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi gagal: $e',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Abstract background shapes ──────────────────────
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            child: CustomPaint(
              size: const Size(120, 150),
              painter: _AuthCurvePainter(),
            ),
          ),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Back button row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _border, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: _dark, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Logo badge ────────────────────────
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded,
                                    size: 36, color: Colors.white),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: _accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Heading ───────────────────────────────────
                        Center(
                          child: Text(
                            'Daftar',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: _dark,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Lengkapi data untuk membuat akun',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _subtitle,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Form card ─────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _border, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Step indicator dots
                                _buildStepIndicator(),
                                const SizedBox(height: 24),

                                // Nama Lengkap
                                _buildField(
                                  controller: _nameController,
                                  label: 'Nama Lengkap',
                                  icon: Icons.person_outline_rounded,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Nama tidak boleh kosong'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Email
                                _buildField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                      return 'Format email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                _buildField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _subtitle,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                                    if (v.length < 6) return 'Password minimal 6 karakter';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Konfirmasi Password
                                _buildField(
                                  controller: _confirmPasswordController,
                                  label: 'Konfirmasi Password',
                                  icon: Icons.lock_reset_rounded,
                                  obscure: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _subtitle,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                                    if (v != _passwordController.text) return 'Password tidak cocok';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                // Daftar button
                                _buildPrimaryButton(
                                  label: 'Daftar Sekarang',
                                  isLoading: _isLoading,
                                  onPressed: _handleRegister,
                                ),

                                const SizedBox(height: 24),

                                // Login link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sudah punya akun? ',
                                      style: GoogleFonts.poppins(
                                          color: _subtitle, fontSize: 13),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Text(
                                        'Masuk',
                                        style: GoogleFonts.poppins(
                                          color: _primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        Container(
          width: 32, height: 6,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 20, height: 6,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 12, height: 6,
          decoration: BoxDecoration(
            color: _iconBg,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  // ── Shared field builder ──────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscure,
      style: GoogleFonts.poppins(fontSize: 14, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: _subtitle, fontSize: 14),
        floatingLabelStyle: GoogleFonts.poppins(
            color: _primary, fontSize: 13, fontWeight: FontWeight.w600),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _iconBg, width: 1.5),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accent, _accent,
                      _primary, _primary,
                    ],
                    stops: [0.0, 0.35, 0.35, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: _dark, size: 16),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Curve painter ─────────────────────────────────────────────────────────────
class _AuthCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4FF59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
        const Offset(20, 20), 8, paint..style = PaintingStyle.fill);

    paint.style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(20, 20)
      ..quadraticBezierTo(size.width * 0.7, 10, size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
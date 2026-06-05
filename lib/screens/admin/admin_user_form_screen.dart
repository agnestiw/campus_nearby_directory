import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile_model.dart';
import '../../models/role_model.dart';
import '../../services/user_service.dart';

enum UserFormMode { create, edit, view }

class AdminUserFormScreen extends StatefulWidget {
  const AdminUserFormScreen({
    super.key,
    required this.mode,
    this.user,
  });

  final UserFormMode mode;
  final ProfileModel? user;

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  List<RoleModel> _roles = [];
  RoleModel? _selectedRole;
  bool _isLoading = false;
  String? _error;

  bool get _isViewOnly => widget.mode == UserFormMode.view;
  bool get _isCreate => widget.mode == UserFormMode.create;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    if (widget.user != null) {
      _nameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _phoneController.text = widget.user!.phone ?? '';
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _userService.getRoles();
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _selectedRole = roles.firstWhere(
          (role) => role.id == widget.user?.roleId,
          orElse: () => roles.isNotEmpty ? roles.first : RoleModel(id: 1, name: 'user'),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar role: $e';
      });
    }
  }

  Future<void> _saveUser() async {
    if (_isViewOnly) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih role terlebih dahulu.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isCreate) {
        await _userService.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          roleId: _selectedRole!.id,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      } else {
        await _userService.updateUser(
          userId: widget.user!.id,
          fullName: _nameController.text.trim(),
          roleId: _selectedRole!.id,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCreate ? 'User berhasil dibuat' : 'Perubahan user berhasil disimpan', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF9CA3AF)),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF1A6FDB),
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isCreate
        ? 'Tambah User'
        : _isViewOnly
            ? 'Lihat User'
            : 'Ubah User';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 60),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE8EEFD),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: _error != null && _roles.isEmpty
            ? Center(child: Text(_error!, style: GoogleFonts.poppins(color: theme.colorScheme.error, fontSize: 14)))
            : _roles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isViewOnly,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDeco('Nama Lengkap *', theme),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: _isCreate,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDeco('Email *', theme),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
                            if (!value.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !_isViewOnly,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDeco('Nomor Telepon', theme),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<RoleModel>(
                          value: _selectedRole,
                          style: GoogleFonts.poppins(fontSize: 14, color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B)),
                          items: _roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.name[0].toUpperCase() + role.name.substring(1)),
                                ),
                              )
                              .toList(),
                          onChanged: _isViewOnly
                              ? null
                              : (role) => setState(() => _selectedRole = role),
                          decoration: _inputDeco('Role *', theme),
                          validator: (value) => value == null ? 'Pilih role dulu' : null,
                        ),
                        if (_isCreate) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            enabled: true,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDeco('Password *', theme),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!, style: GoogleFonts.poppins(color: theme.colorScheme.error, fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        if (!_isViewOnly)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A6FDB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Simpan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

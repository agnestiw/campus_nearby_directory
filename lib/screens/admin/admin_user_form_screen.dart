import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
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
        const SnackBar(content: Text('Pilih role terlebih dahulu.')),
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
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isCreate
        ? 'Tambah User'
        : _isViewOnly
            ? 'Lihat User'
            : 'Ubah User';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _error != null
            ? Center(child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)))
            : _roles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isViewOnly,
                          decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          enabled: _isCreate,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
                            if (!value.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !_isViewOnly,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<RoleModel>(
                          value: _selectedRole,
                          items: _roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.name),
                                ),
                              )
                              .toList(),
                          onChanged: _isViewOnly
                              ? null
                              : (role) => setState(() => _selectedRole = role),
                          decoration: const InputDecoration(labelText: 'Role'),
                          validator: (value) => value == null ? 'Pilih role dulu' : null,
                        ),
                        if (_isCreate) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            enabled: true,
                            decoration: const InputDecoration(labelText: 'Password'),
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
                          Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                        if (!_isViewOnly)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveUser,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan'),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

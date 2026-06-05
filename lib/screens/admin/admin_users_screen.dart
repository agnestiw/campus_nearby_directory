import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'Ahmad Fauzi',
      'email': 'ahmad.fauzi@email.com',
      'role': 'User',
      'joinDate': '12 Mei 2025',
      'status': 'Active',
    },
    {
      'id': '2',
      'name': 'Siti Nurhaliza',
      'email': 'siti.nur@email.com',
      'role': 'User',
      'joinDate': '08 Mei 2025',
      'status': 'Active',
    },
    {
      'id': '3',
      'name': 'Budi Santoso',
      'email': 'budi.santoso@email.com',
      'role': 'Admin',
      'joinDate': '01 Mei 2025',
      'status': 'Inactive',
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      return u['name'].toString().toLowerCase().contains(q) ||
          u['email'].toString().toLowerCase().contains(q);
    }).toList();
  }

  void _toggleUserStatus(String userId) {
    setState(() {
      final idx = _users.indexWhere((u) => u['id'] == userId);
      if (idx != -1) {
        _users[idx]['status'] =
            _users[idx]['status'] == 'Active' ? 'Inactive' : 'Active';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status user diubah')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Kelola User',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada user ditemukan',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (_, i) {
                      final user = _filteredUsers[i];
                      final isActive = user['status'] == 'Active';
                      final isAdmin = user['role'] == 'Admin';
                      return _UserCard(
                        user: user,
                        isActive: isActive,
                        isAdmin: isAdmin,
                        onToggle: () => _toggleUserStatus(user['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Card — TIDAK pakai ListTile agar layout bisa dikontrol penuh
// Ini solusi utama untuk RIGHT OVERFLOW & BOTTOM OVERFLOW
// ─────────────────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isActive,
    required this.isAdmin,
    required this.onToggle,
  });

  final Map<String, dynamic> user;
  final bool isActive;
  final bool isAdmin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final initial = user['name'].toString()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: AppTheme.primaryLight,
            radius: 22,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info — Expanded agar tidak overflow ke kanan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + badge role
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user['name'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                // Email
                Text(
                  user['email'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),

                // Tanggal + status chip — TIDAK pakai Spacer (penyebab overflow)
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text(
                      user['joinDate'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.accent.withOpacity(0.12)
                            : AppTheme.danger.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppTheme.accent : AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Switch — di luar Expanded, lebar tetap ~40px
          const SizedBox(width: 4),
          Switch(
            value: isActive,
            activeColor: AppTheme.accent,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
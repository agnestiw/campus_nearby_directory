import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = false;
  String _searchQuery = '';

  // TODO: Ganti dengan data real dari UserService nanti
  final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'Ahmad Fauzi',
      'email': 'ahmad.fauzi@email.com',
      'role': 'User',
      'joinDate': '12 Mei 2025',
      'status': 'Active'
    },
    {
      'id': '2',
      'name': 'Siti Nurhaliza',
      'email': 'siti.nur@email.com',
      'role': 'User',
      'joinDate': '08 Mei 2025',
      'status': 'Active'
    },
    {
      'id': '3',
      'name': 'Budi Santoso',
      'email': 'budi.santoso@email.com',
      'role': 'Admin',
      'joinDate': '01 Mei 2025',
      'status': 'Inactive'
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _toggleUserStatus(String userId) async {
    // TODO: Implementasi dengan UserService nanti
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status user diubah (demo)')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Kelola User',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Tambah user baru
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(child: Text('Tidak ada user ditemukan'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isActive = user['status'] == 'Active';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF64748B),
                            child: Text(
                              user['name'].toString()[0],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            user['name'],
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email']),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Role: ${user['role']}'),
                                  const Spacer(),
                                  Text('Bergabung: ${user['joinDate']}'),
                                ],
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: isActive,
                            activeColor: Colors.green,
                            onChanged: (val) => _toggleUserStatus(user['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
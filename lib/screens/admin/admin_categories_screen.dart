import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_category_form_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _categoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
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

  Future<void> _deleteCategory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Kategori', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus kategori ini?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: GoogleFonts.poppins(color: AppTheme.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _categoryService.deleteCategory(id);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kategori berhasil dihapus', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kategori: $e', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openForm({CategoryModel? category}) async {
    final changed = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCategoryFormScreen(
          mode: category == null ? CategoryFormMode.create : CategoryFormMode.edit,
          category: category,
        ),
      ),
    );
    if (changed == true) {
      await _loadCategories();
    }
  }

  Widget _buildCategoryIcon(String name, ThemeData theme) {
    final lower = name.toLowerCase();
    
    // 1. Kesehatan
    if (lower.contains('kesehatan') || lower.contains('klinik')) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, color: theme.brightness == Brightness.dark ? const Color(0xFF3B82F6) : const Color(0xFF1A6FDB), size: 28),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              color: theme.cardColor,
              child: const Icon(Icons.add, color: Color(0xFFD4FF59), size: 16),
            ),
          ),
        ],
      );
    }
    
    // 2. Kos
    if (lower.contains('kos') || lower.contains('penginapan')) {
      return _buildShaderIcon(
        Icons.bed_outlined, 
        begin: Alignment.centerLeft, 
        end: Alignment.centerRight, 
        stop: 0.35,
      );
    }
    
    // 3. Minimarket
    if (lower.contains('minimarket') || lower.contains('toko')) {
      return _buildShaderIcon(
        Icons.storefront_outlined, 
        begin: Alignment.topCenter, 
        end: Alignment.bottomCenter, 
        stop: 0.38,
      );
    }
    
    // 4. ATM
    if (lower.contains('atm') || lower.contains('bank')) {
      return _buildShaderIcon(
        Icons.credit_card_outlined, 
        begin: Alignment.bottomRight, 
        end: Alignment.topLeft, 
        stop: 0.35,
      );
    }
    
    // 5. Makan
    if (lower.contains('makan') || lower.contains('cafe') || lower.contains('kantin')) {
      return _buildShaderIcon(
        Icons.restaurant_outlined, 
        begin: Alignment.centerLeft, 
        end: Alignment.centerRight, 
        stop: 0.4,
      );
    }
    
    // Default
    return _buildShaderIcon(
      Icons.category_outlined,
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      stop: 0.3,
    );
  }

  Widget _buildShaderIcon(IconData icon, {required Alignment begin, required Alignment end, required double stop}) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: begin,
          end: end,
          colors: const [Color(0xFFD4FF59), Color(0xFFD4FF59), Color(0xFF1A6FDB), Color(0xFF1A6FDB)],
          stops: [0.0, stop, stop, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                'Kelola Kategori',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(type: ErrorType.network, onRetry: _loadCategories)
              : _categories.isEmpty
                  ? Center(child: Text('Belum ada kategori', style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _categories.length,
                      itemBuilder: (_, index) {
                        final category = _categories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE8EEFD),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left Icon container
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.brightness == Brightness.dark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE8EEFD),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: _buildCategoryIcon(category.name, theme),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Middle details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name[0].toUpperCase() + category.name.substring(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID Kategori: ${category.id}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Right Actions (Edit & Delete side by side)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ActionBtn(
                                    icon: Icons.edit_rounded,
                                    color: AppTheme.primary,
                                    onTap: () => _openForm(category: category),
                                    tooltip: 'Ubah',
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionBtn(
                                    icon: Icons.delete_rounded,
                                    color: AppTheme.danger,
                                    onTap: () => _deleteCategory(category.id),
                                    tooltip: 'Hapus',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.color, required this.onTap, required this.tooltip});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

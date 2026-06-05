import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/place_model.dart';
import '../../models/category_model.dart';
import '../../services/place_service.dart';
import '../../services/category_service.dart';
import '../../core/app_theme.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_place_form_screen.dart';

class AdminPlacesScreen extends StatefulWidget {
  const AdminPlacesScreen({super.key});

  @override
  State<AdminPlacesScreen> createState() => _AdminPlacesScreenState();
}

class _AdminPlacesScreenState extends State<AdminPlacesScreen> {
  final PlaceService _placeService = PlaceService();
  final CategoryService _categoryService = CategoryService();

  List<PlaceModel> _places = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final places = await _placeService.getPlaces();
      final cats = await _categoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _places = places;
        _categories = cats;
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

  List<PlaceModel> get _filteredPlaces {
    return _places.where((place) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          place.name.toLowerCase().contains(q) ||
          (place.address.toLowerCase().contains(q));
      final matchesCategory =
          _selectedCategoryId == null || place.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _deletePlace(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Tempat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus tempat ini?', style: GoogleFonts.poppins()),
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
      await _placeService.deletePlace(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tempat berhasil dihapus', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menghapus: $e', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openPlaceForm({PlaceModel? place, required PlaceFormMode mode}) async {
    final changed = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPlaceFormScreen(mode: mode, place: place),
      ),
    );
    if (changed == true) {
      await _loadData();
    }
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
                'Kelola Tempat',
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
        onPressed: () => _openPlaceForm(mode: PlaceFormMode.create),
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Search & Filter ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE8EEFD),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Oval Search Bar with shadow
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau alamat...',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1A6FDB), size: 22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(
                          label: 'Semua',
                          selected: _selectedCategoryId == null,
                          onTap: () =>
                              setState(() => _selectedCategoryId = null),
                        ),
                        ..._categories.map((cat) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _chip(
                                label: cat.name[0].toUpperCase() + cat.name.substring(1),
                                selected: _selectedCategoryId == cat.id,
                                onTap: () => setState(() {
                                  _selectedCategoryId =
                                      _selectedCategoryId == cat.id
                                          ? null
                                          : cat.id;
                                }),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorStateWidget(
                        type: ErrorType.network, onRetry: _loadData)
                    : _filteredPlaces.isEmpty
                        ? Center(
                            child: Text('Tidak ada data',
                                style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF64748B))),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredPlaces.length,
                            itemBuilder: (_, i) {
                              final place = _filteredPlaces[i];
                              final cat = _categories.firstWhere(
                                (c) => c.id == place.categoryId,
                                orElse: () =>
                                    CategoryModel(id: 0, name: 'Lainnya'),
                              );
                              return _PlaceCard(
                                place: place,
                                category: cat,
                                onDelete: () => _deletePlace(place.id),
                                onEdit: () => _openPlaceForm(place: place, mode: PlaceFormMode.edit),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A6FDB)
              : (theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF1A6FDB)
                : (theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (theme.brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Place Card — Mengikuti layout PlaceCard user dengan tombol edit & delete vertikal
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.category,
    required this.onDelete,
    required this.onEdit,
  });

  final PlaceModel place;
  final CategoryModel category;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = AppTheme.getCategoryColor(category.name);

    return Container(
      height: 135,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
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
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: SizedBox(
              width: 120,
              height: double.infinity,
              child: CachedNetworkImage(
                imageUrl: place.photoUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: Icon(Icons.place_rounded, size: 30, color: theme.hintColor),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: Icon(Icons.broken_image_rounded, size: 30, color: theme.hintColor),
                ),
              ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category.name[0].toUpperCase() + category.name.substring(1),
                      style: TextStyle(
                        color: catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Place Name
                  Text(
                    place.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),

                  // Rating & Hours
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${place.rating != null ? place.rating!.toStringAsFixed(1) : '-'}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place.openHour ?? 'Jam buka -',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: AppTheme.primary,
                  onTap: onEdit,
                  tooltip: 'Ubah',
                ),
                const SizedBox(height: 8),
                _ActionBtn(
                  icon: Icons.delete_rounded,
                  color: AppTheme.danger,
                  onTap: onDelete,
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
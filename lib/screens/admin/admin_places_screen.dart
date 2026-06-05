import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
          (place.address?.toLowerCase().contains(q) ?? false);
      final matchesCategory =
          _selectedCategoryId == null || place.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _deletePlace(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tempat'),
        content: const Text('Apakah Anda yakin ingin menghapus tempat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppTheme.danger)),
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
          const SnackBar(content: Text('✅ Tempat berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal menghapus: $e')),
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
      appBar: AppBar(
        title: Text(
          'Kelola Tempat',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPlaceForm(mode: PlaceFormMode.create),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Search & Filter ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau alamat...',
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
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
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
                                label: cat.name,
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
                                style: theme.textTheme.bodyMedium),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary
              : Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Place Card — TIDAK pakai ListTile agar trailing tidak overflow
// Tombol edit & delete disusun Column (vertikal) bukan Row
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
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: place.photoUrl ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 64,
                  height: 64,
                  color: theme.inputDecorationTheme.fillColor,
                  child: Icon(Icons.place_rounded,
                      size: 30, color: theme.hintColor),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: theme.inputDecorationTheme.fillColor,
                  child: Icon(Icons.broken_image_rounded,
                      size: 30, color: theme.hintColor),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info — Expanded wajib agar tidak overflow ke kanan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  Text(
                    place.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),

                  // Alamat
                  Text(
                    place.address ?? '-',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),

                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tombol edit & delete VERTIKAL — tidak overflow
            // Row dua IconButton di trailing ListTile = penyebab overflow
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: AppTheme.primary,
                  onTap: onEdit,
                  tooltip: 'Edit',
                ),
                const SizedBox(height: 4),
                _ActionBtn(
                  icon: Icons.delete_rounded,
                  color: AppTheme.danger,
                  onTap: onDelete,
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
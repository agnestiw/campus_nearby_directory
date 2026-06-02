import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/place_model.dart';
import '../../models/category_model.dart';
import '../../services/place_service.dart';
import '../../services/category_service.dart';
import '../../core/app_theme.dart';
import '../../widgets/error_state_widget.dart';

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
    setState(() => _isLoading = true);
    try {
      final places = await _placeService.getPlaces();
      final cats = await _categoryService.getCategories();

      setState(() {
        _places = places;
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PlaceModel> get _filteredPlaces {
    return _places.where((place) {
      final matchesSearch = 
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (place.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _selectedCategoryId == null || place.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _deletePlace(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tempat'),
        content: const Text('Apakah Anda yakin ingin menghapus tempat ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Kelola Tempat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.pushNamed(context, '/admin/add-place');
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau alamat...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(label: const Text('Semua'), selected: _selectedCategoryId == null, onSelected: (v) => setState(() => _selectedCategoryId = null)),
                      ..._categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: _selectedCategoryId == cat.id,
                              onSelected: (v) => setState(() => _selectedCategoryId = v ? cat.id : null),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorStateWidget(type: ErrorType.network, onRetry: _loadData)
                    : _filteredPlaces.isEmpty
                        ? const Center(child: Text('Tidak ada data'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPlaces.length,
                            itemBuilder: (context, index) {
                              final place = _filteredPlaces[index];
                              final cat = _categories.firstWhere(
                                (c) => c.id == place.categoryId,
                                orElse: () => CategoryModel(id: 0, name: 'Lainnya'),
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: place.photoUrl ?? '',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Icon(Icons.place, size: 40),
                                    ),
                                  ),
                                  title: Text(place.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  subtitle: Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePlace(place.id)),
                                    ],
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
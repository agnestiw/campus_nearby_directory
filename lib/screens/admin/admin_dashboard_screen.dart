import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/place_model.dart';
import '../../models/category_model.dart';
import '../../services/place_service.dart';
import '../../services/category_service.dart';
import '../../core/app_theme.dart';
import '../../widgets/error_state_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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

      final matchesCategory = 
          _selectedCategoryId == null || place.categoryId == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _deletePlace(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tempat'),
        content: const Text('Apakah Anda yakin ingin menghapus tempat ini?\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _placeService.deletePlace(id);   // Akan kita tambahkan di service
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
        title: Text(
          'Kelola Tempat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.pushNamed(context, '/admin/add-place');
        },
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
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
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: _selectedCategoryId == null,
                        onSelected: (val) => setState(() => _selectedCategoryId = null),
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: _selectedCategoryId == cat.id,
                              onSelected: (val) => setState(() {
                                _selectedCategoryId = val ? cat.id : null;
                              }),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List Tempat
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorStateWidget(
                        type: ErrorType.network,
                        onRetry: _loadData,
                      )
                    : _filteredPlaces.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada tempat ditemukan',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPlaces.length,
                            itemBuilder: (context, index) {
                              final place = _filteredPlaces[index];
                              final category = _categories.firstWhere(
                                (c) => c.id == place.categoryId,
                                orElse: () => CategoryModel(id: 0, name: 'Lainnya'),
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: place.photoUrl ?? '',
                                            width: 85,
                                            height: 85,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.place, size: 40, color: Colors.grey),
                                            ),
                                            errorWidget: (_, __, ___) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.place, size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      place.name,
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16.5,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.getCategoryColor(category.name).withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      category.name,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: AppTheme.getCategoryColor(category.name),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                place.address,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  if (place.rating != null)
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.star_rounded, size: 17, color: Color(0xFFF59E0B)),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          place.rating!.toStringAsFixed(1),
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                        ),
                                                      ],
                                                    ),
                                                  const Spacer(),
                                                  Text(
                                                    'ID: ${place.id}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
                                              onPressed: () {},
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                              onPressed: () => _deletePlace(place.id),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
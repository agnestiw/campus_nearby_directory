import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/place_model.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../services/place_service.dart';

enum PlaceFormMode { create, edit, view }

class AdminPlaceFormScreen extends StatefulWidget {
  const AdminPlaceFormScreen({
    super.key,
    required this.mode,
    this.place,
  });

  final PlaceFormMode mode;
  final PlaceModel? place;

  @override
  State<AdminPlaceFormScreen> createState() => _AdminPlaceFormScreenState();
}

class _AdminPlaceFormScreenState extends State<AdminPlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placeService = PlaceService();
  final _categoryService = CategoryService();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _openHourController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  String? _error;

  bool get _isViewOnly => widget.mode == PlaceFormMode.view;
  bool get _isCreate => widget.mode == PlaceFormMode.create;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.place != null) {
      final place = widget.place!;
      _nameController.text = place.name;
      _addressController.text = place.address;
      _latitudeController.text = place.latitude.toString();
      _longitudeController.text = place.longitude.toString();
      _openHourController.text = place.openHour ?? '';
      _descriptionController.text = place.description ?? '';
      _photoUrlController.text = place.photoUrl ?? '';
      _ratingController.text = place.rating?.toString() ?? '';
      _phoneController.text = place.phone ?? '';
      _websiteController.text = place.website ?? '';
      _selectedCategoryId = place.categoryId;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (_selectedCategoryId == null && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _savePlace() async {
    if (_isViewOnly) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final place = PlaceModel(
        id: widget.place?.id ?? 0,
        categoryId: _selectedCategoryId!,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        openHour: _openHourController.text.trim().isEmpty ? null : _openHourController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        photoUrl: _photoUrlController.text.trim().isEmpty ? null : _photoUrlController.text.trim(),
        rating: _ratingController.text.trim().isEmpty ? null : double.tryParse(_ratingController.text.trim()),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      );

      if (_isCreate) {
        await _placeService.createPlace(place);
      } else {
        await _placeService.updatePlace(place);
      }
      if (!mounted) return;
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
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _openHourController.dispose();
    _descriptionController.dispose();
    _photoUrlController.dispose();
    _ratingController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
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
        ? 'Tambah Tempat'
        : _isViewOnly
            ? 'Lihat Tempat'
            : 'Ubah Tempat';

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
        child: _categories.isEmpty
            ? _error != null
                ? Center(child: Text(_error!, style: GoogleFonts.poppins(color: theme.colorScheme.error, fontSize: 14)))
                : const Center(child: CircularProgressIndicator())
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
                      decoration: _inputDeco('Nama Tempat *', theme),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      enabled: !_isViewOnly,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDeco('Alamat', theme),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            enabled: !_isViewOnly,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDeco('Latitude *', theme),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Latitude wajib';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            enabled: !_isViewOnly,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDeco('Longitude *', theme),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Longitude wajib';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      style: GoogleFonts.poppins(fontSize: 14, color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B132B)),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name[0].toUpperCase() + category.name.substring(1)),
                            ),
                          )
                          .toList(),
                      onChanged: _isViewOnly ? null : (value) => setState(() => _selectedCategoryId = value),
                      decoration: _inputDeco('Kategori *', theme),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _openHourController,
                      enabled: !_isViewOnly,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDeco('Jam Buka', theme),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isViewOnly,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDeco('Deskripsi', theme),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _photoUrlController,
                      enabled: !_isViewOnly,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDeco('URL Foto', theme),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ratingController,
                      enabled: !_isViewOnly,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDeco('Rating', theme),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isViewOnly,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDeco('Telepon', theme),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      enabled: !_isViewOnly,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDeco('Website', theme),
                      keyboardType: TextInputType.url,
                    ),
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
                          onPressed: _isLoading ? null : _savePlace,
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

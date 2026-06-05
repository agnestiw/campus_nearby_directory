import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu')));
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isCreate
        ? 'Tambah Tempat'
        : _isViewOnly
            ? 'Lihat Tempat'
            : 'Ubah Tempat';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _categories.isEmpty
            ? _error != null
                ? Center(child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)))
                : const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'Nama Tempat'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'Alamat'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            enabled: !_isViewOnly,
                            decoration: const InputDecoration(labelText: 'Latitude'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Latitude wajib diisi';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Latitude tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            enabled: !_isViewOnly,
                            decoration: const InputDecoration(labelText: 'Longitude'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Longitude wajib diisi';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Longitude tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: _isViewOnly ? null : (value) => setState(() => _selectedCategoryId = value),
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _openHourController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'Jam Buka'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _photoUrlController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'URL Foto'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ratingController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'Rating'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'Telepon'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _websiteController,
                      enabled: !_isViewOnly,
                      decoration: const InputDecoration(labelText: 'Website'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                    if (!_isViewOnly)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _savePlace,
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

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

enum CategoryFormMode { create, edit }

class AdminCategoryFormScreen extends StatefulWidget {
  const AdminCategoryFormScreen({
    super.key,
    required this.mode,
    this.category,
  });

  final CategoryFormMode mode;
  final CategoryModel? category;

  @override
  State<AdminCategoryFormScreen> createState() => _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryService = CategoryService();
  bool _isLoading = false;
  String? _error;

  bool get _isCreate => widget.mode == CategoryFormMode.create;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isCreate) {
        await _categoryService.createCategory(_nameController.text.trim());
      } else {
        await _categoryService.updateCategory(
          widget.category!.id,
          _nameController.text.trim(),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isCreate ? 'Tambah Kategori' : 'Ubah Kategori';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Kategori'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama kategori tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
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

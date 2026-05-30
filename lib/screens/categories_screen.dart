import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoriesScreen
    extends StatefulWidget {
  const CategoriesScreen({
    super.key,
  });

  @override
  State<CategoriesScreen>
      createState() =>
          _CategoriesScreenState();
}

class _CategoriesScreenState
    extends State<CategoriesScreen> {
  final CategoryService
      _categoryService =
      CategoryService();

  late Future<List<CategoryModel>>
      categoriesFuture;

  @override
  void initState() {
    super.initState();

    categoriesFuture =
        _categoryService
            .getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Categories'),
      ),
      body: FutureBuilder<
          List<CategoryModel>>(
        future: categoriesFuture,
        builder: (
          context,
          snapshot,
        ) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No categories found',
              ),
            );
          }

          final categories =
              snapshot.data!;

          print('UI Categories Count: ${categories.length}');

          return ListView.builder(
            itemCount:
                categories.length,
            itemBuilder:
                (context, index) {
              final category =
                  categories[index];

              return ListTile(
                leading: const Icon(
                  Icons.category,
                ),
                title: Text(
                  category.name,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
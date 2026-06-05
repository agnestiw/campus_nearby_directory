import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';

class CategoryService {
  final supabase = Supabase.instance.client;

  Future<List<CategoryModel>> getCategories() async {
    final response = await supabase
        .from('categories')
        .select()
        .order('id');

    return (response as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }

  Future<CategoryModel> createCategory(String name) async {
    final response = await supabase
        .from('categories')
        .insert({'name': name})
        .select()
        .single();
    return CategoryModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateCategory(int id, String name) async {
    await supabase.from('categories').update({'name': name}).eq('id', id);
  }

  Future<void> deleteCategory(int id) async {
    await supabase.from('categories').delete().eq('id', id);
  }

  Future<int> countCategories() async {
    final response = await supabase.from('categories').select('id');
    if (response is List) return response.length;
    return 0;
  }
}
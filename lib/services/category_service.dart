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
}
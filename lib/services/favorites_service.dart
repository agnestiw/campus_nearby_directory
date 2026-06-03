import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  FavoritesService._internal();
  static final FavoritesService _instance =
      FavoritesService._internal();

  factory FavoritesService() => _instance;

  final _supabase = Supabase.instance.client;

  final ValueNotifier<Set<int>> favorites =
      ValueNotifier(<int>{});

  String get _userId =>
      _supabase.auth.currentUser!.id;

  // ==========================
  // LOAD FAVORITES
  // ==========================
  Future<void> loadFavorites() async {
    final response = await _supabase
        .from('favorites')
        .select('place_id')
        .eq('user_id', _userId);

    final ids = (response as List)
        .map((e) => e['place_id'] as int)
        .toSet();

    favorites.value = ids;
  }

  // ==========================
  // CHECK
  // ==========================
  Future<bool> isFavorite(int placeId) async {
    if (favorites.value.isEmpty) {
      await loadFavorites();
    }

    return favorites.value.contains(placeId);
  }

  // ==========================
  // ADD
  // ==========================
  Future<void> addFavorite(int placeId) async {
    await _supabase.from('favorites').insert({
      'user_id': _userId,
      'place_id': placeId,
    });

    final updated =
        Set<int>.from(favorites.value);

    updated.add(placeId);

    favorites.value = updated;
  }

  // ==========================
  // REMOVE
  // ==========================
  Future<void> removeFavorite(int placeId) async {
    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', _userId)
        .eq('place_id', placeId);

    final updated =
        Set<int>.from(favorites.value);

    updated.remove(placeId);

    favorites.value = updated;
  }

  // ==========================
  // TOGGLE
  // ==========================
  Future<bool> toggleFavorite(int placeId) async {
    if (favorites.value.contains(placeId)) {
      await removeFavorite(placeId);
      return false;
    }

    await addFavorite(placeId);
    return true;
  }
}
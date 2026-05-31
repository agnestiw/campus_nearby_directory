import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _kKey = 'favorites';

  FavoritesService._internal();
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;

  SharedPreferences? _prefs;
  final ValueNotifier<Set<int>> favorites = ValueNotifier(<int>{});

  Future<void> _ensureLoaded() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    final list = _prefs!.getStringList(_kKey) ?? <String>[];
    favorites.value = list.map(int.parse).toSet();
  }

  Future<Set<int>> getFavorites() async {
    await _ensureLoaded();
    return favorites.value;
  }

  Future<bool> isFavorite(int id) async {
    await _ensureLoaded();
    return favorites.value.contains(id);
  }

  Future<void> addFavorite(int id) async {
    await _ensureLoaded();
    final set = Set<int>.from(favorites.value);
    set.add(id);
    favorites.value = set;
    await _prefs!.setStringList(_kKey, set.map((e) => e.toString()).toList());
  }

  Future<void> removeFavorite(int id) async {
    await _ensureLoaded();
    final set = Set<int>.from(favorites.value);
    set.remove(id);
    favorites.value = set;
    await _prefs!.setStringList(_kKey, set.map((e) => e.toString()).toList());
  }

  Future<bool> toggleFavorite(int id) async {
    await _ensureLoaded();
    if (favorites.value.contains(id)) {
      await removeFavorite(id);
      return false;
    } else {
      await addFavorite(id);
      return true;
    }
  }
}

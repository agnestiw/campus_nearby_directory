import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../models/place_model.dart';
import 'favorites_service.dart';

class PlaceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FavoritesService _favService = FavoritesService();

  // ─────────────────────────────────────
  // GET ALL PLACES
  // ─────────────────────────────────────
  Future<List<PlaceModel>> getPlaces() async {
    try {
      AppLogger.info('Fetching all places...');

      final response = await _supabase
          .from('places')
          .select()
          .order('name');

      AppLogger.success('Places fetched: ${response.length}');

      final places = (response as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();

      // mark favorites
      await _favService.loadFavorites();
      final favs = _favService.favorites.value;
      for (var p in places) {
        p.isFavorite = favs.contains(p.id);
      }

      return places;
    } catch (e) {
      AppLogger.error('Error fetching places: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────
  // GET PLACE BY ID
  // ─────────────────────────────────────
  Future<PlaceModel?> getPlaceById(int id) async {
    try {
      AppLogger.info('Fetching place id: $id');

      final response = await _supabase
          .from('places')
          .select()
          .eq('id', id)
          .single();

      final place = PlaceModel.fromJson(response);
      place.isFavorite = await _favService.isFavorite(place.id);
      return place;
    } catch (e) {
      AppLogger.error('Error fetching place by id: $e');
      return null;
    }
  }

  // ─────────────────────────────────────
  // GET PLACES BY CATEGORY
  // ─────────────────────────────────────
  Future<List<PlaceModel>> getPlacesByCategory(int categoryId) async {
    try {
      AppLogger.info('Fetching places for category: $categoryId');

      final response = await _supabase
          .from('places')
          .select()
          .eq('category_id', categoryId)
          .order('name');

      AppLogger.success('Category places fetched: ${response.length}');

      final places = (response as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();
      await _favService.loadFavorites();
      final favs = _favService.favorites.value;
      for (var p in places) p.isFavorite = favs.contains(p.id);
      return places;
    } catch (e) {
      AppLogger.error('Error fetching category places: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────
  // SEARCH PLACES BY KEYWORD
  // ─────────────────────────────────────
  Future<List<PlaceModel>> searchPlaces(String keyword) async {
    try {
      AppLogger.info('Searching: $keyword');

      final response = await _supabase
          .from('places')
          .select()
          .ilike('name', '%$keyword%')
          .order('name');

      AppLogger.success('Search result: ${response.length} places');

      final places = (response as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();
      await _favService.loadFavorites();
      final favs = _favService.favorites.value;
      for (var p in places) p.isFavorite = favs.contains(p.id);
      return places;
    } catch (e) {
      AppLogger.error('Search error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────
  // SEARCH + FILTER BY CATEGORY
  // ─────────────────────────────────────
  Future<List<PlaceModel>> searchPlacesByCategory({
    required String keyword,
    required int categoryId,
  }) async {
    try {
      final response = await _supabase
          .from('places')
          .select()
          .eq('category_id', categoryId)
          .ilike('name', '%$keyword%')
          .order('name');

      return (response as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error('Search+filter error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────
  // DELETE PLACE (ADMIN ONLY)
  // ─────────────────────────────────────
  Future<void> deletePlace(int id) async {
    try {
      AppLogger.info('Deleting place id: $id');

      await _supabase
          .from('places')
          .delete()
          .eq('id', id);

      AppLogger.success('Place id $id deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting place id $id: $e');
      rethrow;
    }
  }

  Future<PlaceModel> createPlace(PlaceModel place) async {
    try {
      AppLogger.info('Creating place: ${place.name}');
      final response = await _supabase.from('places').insert({
        'name': place.name,
        'address': place.address,
        'latitude': place.latitude,
        'longitude': place.longitude,
        'category_id': place.categoryId,
        'open_hour': place.openHour,
        'description': place.description,
        'photo_url': place.photoUrl,
        'rating': place.rating,
        'phone': place.phone,
        'website': place.website,
      }).select().single();
      return PlaceModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Error creating place: $e');
      rethrow;
    }
  }

  Future<void> updatePlace(PlaceModel place) async {
    try {
      AppLogger.info('Updating place ${place.id}');
      await _supabase.from('places').update({
        'name': place.name,
        'address': place.address,
        'latitude': place.latitude,
        'longitude': place.longitude,
        'category_id': place.categoryId,
        'open_hour': place.openHour,
        'description': place.description,
        'photo_url': place.photoUrl,
        'rating': place.rating,
        'phone': place.phone,
        'website': place.website,
      }).eq('id', place.id);
    } catch (e) {
      AppLogger.error('Error updating place: $e');
      rethrow;
    }
  }

  Future<int> countPlaces() async {
    try {
      final response = await _supabase.from('places').select('id');
      if (response is List) return response.length;
      return 0;
    } catch (e) {
      AppLogger.error('Error counting places: $e');
      rethrow;
    }
  }

  Future<List<PlaceModel>> getRecentPlaces({int limit = 3}) async {
    try {
      final response = await _supabase
          .from('places')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching recent places: $e');
      return [];
    }
  }
}
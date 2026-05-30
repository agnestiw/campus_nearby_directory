import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../models/place_model.dart';

class PlaceService {
  final supabase = Supabase.instance.client;

  /// ==========================
  /// GET ALL PLACES
  /// ==========================
  Future<List<PlaceModel>> getPlaces() async {
    try {
      AppLogger.info(
        'Fetching all places...',
      );

      final response = await supabase
          .from('places')
          .select()
          .order('name');

      AppLogger.success(
        'Places fetched successfully',
      );

      AppLogger.info(
        'Total places: ${response.length}',
      );

      return (response as List)
          .map(
            (e) => PlaceModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching places: $e',
      );

      rethrow;
    }
  }

  /// ==========================
  /// GET PLACE BY ID
  /// ==========================
  Future<PlaceModel?> getPlaceById(
    int id,
  ) async {
    try {
      AppLogger.info(
        'Fetching place id: $id',
      );

      final response =
          await supabase
              .from('places')
              .select()
              .eq('id', id)
              .single();

      return PlaceModel.fromJson(
        response,
      );
    } catch (e) {
      AppLogger.error(
        'Error fetching place by id: $e',
      );

      return null;
    }
  }

  /// ==========================
  /// GET PLACES BY CATEGORY
  /// ==========================
  Future<List<PlaceModel>>
      getPlacesByCategory(
    int categoryId,
  ) async {
    try {
      AppLogger.info(
        'Fetching category: $categoryId',
      );

      final response =
          await supabase
              .from('places')
              .select()
              .eq(
                'category_id',
                categoryId,
              )
              .order('name');

      AppLogger.success(
        'Category fetched successfully',
      );

      AppLogger.info(
        'Total places: ${response.length}',
      );

      return (response as List)
          .map(
            (e) => PlaceModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching category: $e',
      );

      rethrow;
    }
  }

  /// ==========================
  /// SEARCH PLACE
  /// ==========================
  Future<List<PlaceModel>>
      searchPlaces(
    String keyword,
  ) async {
    try {
      AppLogger.info(
        'Searching: $keyword',
      );

      final response =
          await supabase
              .from('places')
              .select()
              .ilike(
                'name',
                '%$keyword%',
              );

      AppLogger.success(
        'Search success',
      );

      return (response as List)
          .map(
            (e) => PlaceModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      AppLogger.error(
        'Search error: $e',
      );

      rethrow;
    }
  }
}
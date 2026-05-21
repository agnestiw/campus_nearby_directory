import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../models/place_model.dart';

class PlaceService {
  final supabase = Supabase.instance.client;

  Future<List<PlaceModel>> getPlaces() async {
    try {
      AppLogger.info(
        'Fetching places from Supabase...',
      );

      final response = await supabase
          .from('places')
          .select();

      AppLogger.success(
        'Data fetched successfully',
      );

      AppLogger.info(
        'Total data: ${response.length}',
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
}
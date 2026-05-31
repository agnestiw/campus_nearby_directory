import 'place_model.dart';

class PlaceDistanceModel {
  final PlaceModel place;
  final double distanceInMeters;

  PlaceDistanceModel({
    required this.place,
    required this.distanceInMeters,
  });

  /// Format jarak: "350 m" atau "1.2 km"
  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }
}
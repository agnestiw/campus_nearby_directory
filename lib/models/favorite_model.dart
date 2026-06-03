class FavoriteModel {
  final int id;
  final String userId;
  final int placeId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'],
      userId: json['user_id'],
      placeId: json['place_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
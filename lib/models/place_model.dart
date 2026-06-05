class PlaceModel {
  final int id;
  final int categoryId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  String? openHour;
  final String? description;
  final String? photoUrl;
  final double? rating;
  final String? phone;
  final String? website;

  // mutable favorite flag (local only)
  bool isFavorite;

  PlaceModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.openHour,
    this.description,
    this.photoUrl,
    this.rating,
    this.phone,
    this.website,
    this.isFavorite = false,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    try {
      return PlaceModel(
        id: json['id'],
        categoryId: json['category_id'],
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        openHour: json['open_hour'],
        description: json['description'],
        photoUrl: json['photo_url'],
        rating: json['rating'] != null
            ? (json['rating'] as num).toDouble()
            : null,
        phone: json['phone'],
        website: json['website'],
        isFavorite: false,
      );
    } catch (e) {
      throw Exception('Error parsing PlaceModel: $e');
    }
  }

  PlaceModel copyWith({
    int? categoryId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? openHour,
    String? description,
    String? photoUrl,
    double? rating,
    String? phone,
    String? website,
    bool? isFavorite,
  }) {
    return PlaceModel(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openHour: openHour ?? this.openHour,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
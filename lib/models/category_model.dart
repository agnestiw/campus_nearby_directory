class CategoryModel {
  final int id;
  final String name;
  int placeCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.placeCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
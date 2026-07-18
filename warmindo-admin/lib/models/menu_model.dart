class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class MenuModel {
  final String id;
  final String name;
  final String categoryId;
  final Category? category;
  final double price;
  final String description;
  final String image;
  final bool isActive;
  final bool hasSpicyLevel;
  final bool hasTempLevel;
  final bool isFavorite;

  MenuModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.category,
    required this.price,
    required this.description,
    required this.image,
    required this.isActive,
    required this.hasSpicyLevel,
    required this.hasTempLevel,
    required this.isFavorite,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['categoryId'] ?? '',
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      price: (json['price'] is String) ? double.tryParse(json['price']) ?? 0 : (json['price'] as num).toDouble(),
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      isActive: json['isActive'] ?? true,
      hasSpicyLevel: json['hasSpicyLevel'] ?? false,
      hasTempLevel: json['hasTempLevel'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'description': description,
      'image': image,
      'hasSpicyLevel': hasSpicyLevel,
      'hasTempLevel': hasTempLevel,
    };
  }
}

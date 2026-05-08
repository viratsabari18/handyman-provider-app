class ProviderCategories {
  List<CategoryData>? data;

  ProviderCategories({this.data});

  factory ProviderCategories.fromJson(Map<String, dynamic> json) {
    return ProviderCategories(
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => CategoryData.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (data != null) {
      json['data'] = data!.map((e) => e.toJson()).toList();
    }
    return json;
  }
}

class CategoryData {
  int? id;
  String? name;
  int? status;
  String? description;
  int? isFeatured;
  String? color;
  String? categoryImage;
  String? categoryExtension;
  int? services;
  String? deletedAt;

  CategoryData({
    this.id,
    this.name,
    this.status,
    this.description,
    this.isFeatured,
    this.color,
    this.categoryImage,
    this.categoryExtension,
    this.services,
    this.deletedAt,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      description: json['description'],
      isFeatured: json['is_featured'],
      color: json['color'],
      categoryImage: json['category_image'],
      categoryExtension: json['category_extension'],
      services: json['services'],
      deletedAt: json['deleted_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['id'] = id;
    json['name'] = name;
    json['status'] = status;
    json['description'] = description;
    json['is_featured'] = isFeatured;
    json['color'] = color;
    json['category_image'] = categoryImage;
    json['category_extension'] = categoryExtension;
    json['services'] = services;
    json['deleted_at'] = deletedAt;
    return json;
  }
}
// lib/models/registration_fields_response.dart

class ZoneAndCetagoryModel{
  List<Category>? categories;
  List<Zone>? zones;

   ZoneAndCetagoryModel({this.categories, this.zones});

  factory  ZoneAndCetagoryModel.fromJson(Map<String, dynamic> json) {
    return  ZoneAndCetagoryModel(
      categories: json['categories'] != null
          ? (json['categories'] as List).map((i) => Category.fromJson(i)).toList()
          : null,
      zones: json['zones'] != null
          ? (json['zones'] as List).map((i) => Zone.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    if (zones != null) {
      data['zones'] = zones!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Category {
  int? id;
  String? name;
  String? imageUrl; // Adding imageUrl field if needed

  Category({this.id, this.name, this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'] ?? '', // Optional field
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      data['image_url'] = imageUrl;
    }
    return data;
  }
}

class Zone {
  int? id;
  String? name;

  Zone({this.id, this.name});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}
class RegistrationData {
  List<Category>? categories;
  List<Zone>? zones;
  List<ProviderType>? providerTypes;
  List<HandymanType>? handymanTypes;
  List<Document>? documents;
  List<Provider>? providers;

  RegistrationData ({
    this.categories,
    this.zones,
    this.providerTypes,
    this.handymanTypes,
    this.documents,
    this.providers,
  });

  factory  RegistrationData.fromJson(Map<String, dynamic> json) {
    return  RegistrationData(
      categories: json['categories'] != null
          ? (json['categories'] as List).map((i) => Category.fromJson(i)).toList()
          : null,
      zones: json['zones'] != null
          ? (json['zones'] as List).map((i) => Zone.fromJson(i)).toList()
          : null,
      providerTypes: json['provider_types'] != null
          ? (json['provider_types'] as List).map((i) => ProviderType.fromJson(i)).toList()
          : null,
      handymanTypes: json['handyman_types'] != null
          ? (json['handyman_types'] as List).map((i) => HandymanType.fromJson(i)).toList()
          : null,
      documents: json['documents'] != null
          ? (json['documents'] as List).map((i) => Document.fromJson(i)).toList()
          : null,
      providers: json['providers'] != null
          ? (json['providers'] as List).map((i) => Provider.fromJson(i)).toList()
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
    if (providerTypes != null) {
      data['provider_types'] = providerTypes!.map((v) => v.toJson()).toList();
    }
    if (handymanTypes != null) {
      data['handyman_types'] = handymanTypes!.map((v) => v.toJson()).toList();
    }
    if (documents != null) {
      data['documents'] = documents!.map((v) => v.toJson()).toList();
    }
    if (providers != null) {
      data['providers'] = providers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Category {
  int? id;
  String? name;
  String? imageUrl;

  Category({this.id, this.name, this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'] ?? '',
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

class ProviderType {
  int? id;
  String? name;
  int? commission;
  String? type;

  ProviderType({this.id, this.name, this.commission, this.type});

  factory ProviderType.fromJson(Map<String, dynamic> json) {
    return ProviderType(
      id: json['id'],
      name: json['name'],
      commission: json['commission'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['commission'] = commission;
    data['type'] = type;
    return data;
  }
}

class HandymanType {
  int? id;
  String? name;
  int? commission;
  String? type;

  HandymanType({this.id, this.name, this.commission, this.type});

  factory HandymanType.fromJson(Map<String, dynamic> json) {
    return HandymanType(
      id: json['id'],
      name: json['name'],
      commission: json['commission'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['commission'] = commission;
    data['type'] = type;
    return data;
  }
}

class Document {
  int? id;
  String? name;
  int? isRequired;

  Document({this.id, this.name, this.isRequired});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      name: json['name'],
      isRequired: json['is_required'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['is_required'] = isRequired;
    return data;
  }
}

class Provider {
  int? id;
  String? name;

  Provider({this.id, this.name});

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
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
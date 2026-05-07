class ProvidersServices {
  Pagination? pagination;
  List<ProviderServiceData>? data;

  ProvidersServices({
    this.pagination,
    this.data,
  });

  ProvidersServices.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;

    if (json['data'] != null) {
      data = <ProviderServiceData>[];
      json['data'].forEach((v) {
        data!.add(ProviderServiceData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};

    if (pagination != null) {
      dataMap['pagination'] = pagination!.toJson();
    }

    if (data != null) {
      dataMap['data'] = data!.map((v) => v.toJson()).toList();
    }

    return dataMap;
  }
}

class Pagination {
  int? totalItems;
  int? perPage;
  int? currentPage;
  int? totalPages;
  int? from;
  int? to;
  dynamic nextPage;
  dynamic previousPage;

  Pagination({
    this.totalItems,
    this.perPage,
    this.currentPage,
    this.totalPages,
    this.from,
    this.to,
    this.nextPage,
    this.previousPage,
  });

  Pagination.fromJson(Map<String, dynamic> json) {
    totalItems = json['total_items'];
    perPage = json['per_page'];
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    from = json['from'];
    to = json['to'];
    nextPage = json['next_page'];
    previousPage = json['previous_page'];
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'per_page': perPage,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'from': from,
      'to': to,
      'next_page': nextPage,
      'previous_page': previousPage,
    };
  }
}

class ProviderServiceData {
  int? id;
  String? name;
  int? categoryId;
  int? subcategoryId;
  dynamic providerId;
  num? price;
  String? priceFormat;
  String? type;
  num? discount;
  String? duration;
  int? status;
  String? description;
  int? isFeatured;
  dynamic providerName;
  String? providerImage;
  dynamic cityId;
  String? categoryName;
  String? subcategoryName;
  List<String>? attchments;
  List<AttachmentArray>? attchmentsArray;
  int? totalReview;
  num? totalRating;
  int? isFavourite;
  List<dynamic>? serviceAddressMapping;
  bool? attchmentExtension;
  dynamic deletedAt;
  int? isSlot;
  List<ServiceSlot>? slots;
  String? visitType;
  int? isEnableAdvancePayment;
  num? advancePaymentAmount;
  String? translations;
  dynamic rejectReason;
  String? serviceRequestStatus;

  ProviderServiceData({
    this.id,
    this.name,
    this.categoryId,
    this.subcategoryId,
    this.providerId,
    this.price,
    this.priceFormat,
    this.type,
    this.discount,
    this.duration,
    this.status,
    this.description,
    this.isFeatured,
    this.providerName,
    this.providerImage,
    this.cityId,
    this.categoryName,
    this.subcategoryName,
    this.attchments,
    this.attchmentsArray,
    this.totalReview,
    this.totalRating,
    this.isFavourite,
    this.serviceAddressMapping,
    this.attchmentExtension,
    this.deletedAt,
    this.isSlot,
    this.slots,
    this.visitType,
    this.isEnableAdvancePayment,
    this.advancePaymentAmount,
    this.translations,
    this.rejectReason,
    this.serviceRequestStatus,
  });

  ProviderServiceData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    categoryId = json['category_id'];
    subcategoryId = json['subcategory_id'];
    providerId = json['provider_id'];
    price = json['price'];
    priceFormat = json['price_format'];
    type = json['type'];
    discount = json['discount'];
    duration = json['duration'];
    status = json['status'];
    description = json['description'];
    isFeatured = json['is_featured'];
    providerName = json['provider_name'];
    providerImage = json['provider_image'];
    cityId = json['city_id'];
    categoryName = json['category_name'];
    subcategoryName = json['subcategory_name'];

    if (json['attchments'] != null) {
      attchments = List<String>.from(json['attchments']);
    }

    if (json['attchments_array'] != null) {
      attchmentsArray = <AttachmentArray>[];
      json['attchments_array'].forEach((v) {
        attchmentsArray!.add(AttachmentArray.fromJson(v));
      });
    }

    totalReview = json['total_review'];
    totalRating = json['total_rating'];
    isFavourite = json['is_favourite'];

    if (json['service_address_mapping'] != null) {
      serviceAddressMapping =
          List<dynamic>.from(json['service_address_mapping']);
    }

    attchmentExtension = json['attchment_extension'];
    deletedAt = json['deleted_at'];
    isSlot = json['is_slot'];

    if (json['slots'] != null) {
      slots = <ServiceSlot>[];
      json['slots'].forEach((v) {
        slots!.add(ServiceSlot.fromJson(v));
      });
    }

    visitType = json['visit_type'];
    isEnableAdvancePayment = json['is_enable_advance_payment'];
    advancePaymentAmount = json['advance_payment_amount'];
    translations = json['translations'];
    rejectReason = json['reject_reason'];
    serviceRequestStatus = json['service_request_status'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'provider_id': providerId,
      'price': price,
      'price_format': priceFormat,
      'type': type,
      'discount': discount,
      'duration': duration,
      'status': status,
      'description': description,
      'is_featured': isFeatured,
      'provider_name': providerName,
      'provider_image': providerImage,
      'city_id': cityId,
      'category_name': categoryName,
      'subcategory_name': subcategoryName,
      'attchments': attchments,
      'attchments_array':
          attchmentsArray?.map((v) => v.toJson()).toList(),
      'total_review': totalReview,
      'total_rating': totalRating,
      'is_favourite': isFavourite,
      'service_address_mapping': serviceAddressMapping,
      'attchment_extension': attchmentExtension,
      'deleted_at': deletedAt,
      'is_slot': isSlot,
      'slots': slots?.map((v) => v.toJson()).toList(),
      'visit_type': visitType,
      'is_enable_advance_payment': isEnableAdvancePayment,
      'advance_payment_amount': advancePaymentAmount,
      'translations': translations,
      'reject_reason': rejectReason,
      'service_request_status': serviceRequestStatus,
    };
  }
}

class AttachmentArray {
  int? id;
  String? url;

  AttachmentArray({
    this.id,
    this.url,
  });

  AttachmentArray.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
    };
  }
}

class ServiceSlot {
  String? day;
  List<dynamic>? slot;

  ServiceSlot({
    this.day,
    this.slot,
  });

  ServiceSlot.fromJson(Map<String, dynamic> json) {
    day = json['day'];

    if (json['slot'] != null) {
      slot = List<dynamic>.from(json['slot']);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'slot': slot,
    };
  }
}

class AddProviderCategoryRequest {
  List<int>? categoryId;

  AddProviderCategoryRequest({
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
    };
  }
}


class AddProviderCategoryResponse {
  String? message;
  bool? status;

  AddProviderCategoryResponse({
    this.message,
    this.status,
  });

  factory AddProviderCategoryResponse.fromJson(Map<String, dynamic> json) {
    return AddProviderCategoryResponse(
      message: json['message'] as String?,
      status: json['status'] as bool?,
    );
  }
}
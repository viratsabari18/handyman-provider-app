
class deleteProviderCategoryRequest {
  int? categoryId;

  deleteProviderCategoryRequest({
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
    };
  }
}


class deleteProviderCategoryResponse {
  String? message;
  bool? status;

   deleteProviderCategoryResponse({
    this.message,
    this.status,
  });

  factory  deleteProviderCategoryResponse.fromJson(Map<String, dynamic> json) {
    return  deleteProviderCategoryResponse(
      message: json['message'] as String?,
      status: json['status'] as bool?,
    );
  }
}
class RegisterRequest {
  String firstName;
  String lastName;
  String username;
  String email;
  String password;
  String contactNumber;
  String userType;

  // Provider
  int? providerTypeId;

  // Handyman
  int? providerId;
  int? handymanTypeId;

  List<int>? categoryIds;
  List<int>? serviceZones;
  List<int>? documentIds;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
    required this.contactNumber,
    required this.userType,
    this.providerTypeId,
    this.providerId,
    this.handymanTypeId,
    this.categoryIds,
    this.serviceZones,
    this.documentIds,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      "first_name": firstName,
      "last_name": lastName,
      "username": username,
      "email": email,
      "password": password,
      "contact_number": contactNumber,
      "user_type": userType,
    };

    /// Provider
    if (userType == "provider") {
      data["providertype_id"] = providerTypeId;
      data["category_ids"] = categoryIds;
      data["service_zones"] = serviceZones;
    }

    /// Handyman
    if (userType == "handyman") {
      data["provider_id"] = providerId;
      data["handymantype_id"] = handymanTypeId;
    }

    data["document_id"] = documentIds;

    return data;
  }
}
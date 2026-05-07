
class AddProviderZoneRequest {
  List<int>? zoneId;

  AddProviderZoneRequest({
    this.zoneId,
  });

  Map<String, dynamic> toJson() {
    return {
      'zone_id': zoneId,
    };
  }
}


class AddProviderZoneResponse {
  String? message;
  bool? status;

 AddProviderZoneResponse({
    this.message,
    this.status,
  });

  factory AddProviderZoneResponse.fromJson(Map<String, dynamic> json) {
    return AddProviderZoneResponse(
      message: json['message'] as String?,
      status: json['status'] as bool?,
    );
  }
}
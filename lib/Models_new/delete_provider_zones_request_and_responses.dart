
class deleteProviderZoneRequest {
  int? zoneId;

  deleteProviderZoneRequest({
    this.zoneId,
  });

  Map<String, dynamic> toJson() {
    return {
      'zone_id': zoneId,
    };
  }
}


class deleteProviderZoneResponse {
  String? message;
  bool? status;

   deleteProviderZoneResponse({
    this.message,
    this.status,
  });

  factory  deleteProviderZoneResponse.fromJson(Map<String, dynamic> json) {
    return  deleteProviderZoneResponse(
      message: json['message'] as String?,
      status: json['status'] as bool?,
    );
  }
}
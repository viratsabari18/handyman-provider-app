import 'package:handyman_provider_flutter/Models%20new/registration_data.dart';

class ProviderZones {
  List<Zone>? data;

  ProviderZones({this.data});

  factory ProviderZones.fromJson(Map<String, dynamic> json) {
    return ProviderZones(
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => Zone.fromJson(e))
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


import 'package:handyman_provider_flutter/models/user_data.dart';

class LoginResponse {
  UserData? data;

  LoginResponse({this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }
}
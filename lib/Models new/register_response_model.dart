import 'package:handyman_provider_flutter/models/user_data.dart';

class RegisterResponse {
  String? message;
  UserData? data;

  RegisterResponse({this.message, this.data});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'],
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }
}


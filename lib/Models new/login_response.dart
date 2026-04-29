import 'package:handyman_provider_flutter/Models%20new/user_model.dart';

class LoginResponse {
  UserModel? data;

  LoginResponse({this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      data: json['data'] != null ? UserModel.fromJson(json['data']) : null,
    );
  }
}
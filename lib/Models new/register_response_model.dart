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

class UserData {
  int? id;
  String? firstName;
  String? email;

  UserData({this.id, this.firstName, this.email});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      firstName: json['first_name'],
      email: json['email'],
    );
  }
}
class UserModel {
  int? id;
  String? username;
  String? firstName;
  String? lastName;
  String? email;
  String? userType;
  String? contactNumber;
  int? status;
  String? apiToken;
  String? profileImage;

  UserModel({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.userType,
    this.contactNumber,
    this.status,
    this.apiToken,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      userType: json['user_type'],
      contactNumber: json['contact_number'],
      status: json['status'],
      apiToken: json['api_token'],
      profileImage: json['profile_image'],
    );
  }
}
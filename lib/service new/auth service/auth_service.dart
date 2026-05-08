import 'dart:convert';
import 'dart:io';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:http/http.dart' as http;

import '../../Models new/register_request_model.dart';
import '../../Models new/register_response_model.dart';

class AuthService {
  static const String baseUrl = "https://ethically-thaw-bok.ngrok-free.dev/api";

  /// 🔥 REGISTER (your working code) with improved error handling
  static Future<RegisterResponse?> registerUser({
    required RegisterRequest request,
    required List<File> files,
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/register");

      var multipartRequest = http.MultipartRequest("POST", uri);

      multipartRequest.headers.addAll({
        "Accept": "application/json",
      });

      request.toJson().forEach((key, value) {
        if (value == null) return;

        if (value is List) {
          for (int i = 0; i < value.length; i++) {
            multipartRequest.fields['$key[$i]'] = value[i].toString();
          }
        } else {
          multipartRequest.fields[key] = value.toString();
        }
      });

      for (int i = 0; i < files.length; i++) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'provider_document_$i',
            files[i].path,
          ),
        );
      }

      final response = await http.Response.fromStream(await multipartRequest.send());

      final data = jsonDecode(response.body);

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER RESPONSE: $data");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - return the parsed response
        return RegisterResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        // Validation errors
        String errorMessage = data['message'] ?? "Validation failed";
        
        // Extract specific validation errors if available
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final errorStrings = <String>[];
          
          errors.forEach((field, messages) {
            if (messages is List) {
              errorStrings.add('${field.toUpperCase()}: ${messages.join(', ')}');
            } else {
              errorStrings.add('${field.toUpperCase()}: $messages');
            }
          });
          
          if (errorStrings.isNotEmpty) {
            errorMessage = errorStrings.join('\n');
          }
        }
        
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        // Unauthorized
        throw Exception(data['message'] ?? "Unauthorized. Please check your credentials.");
      } else if (response.statusCode == 403) {
        // Forbidden
        throw Exception(data['message'] ?? "Access forbidden. Please contact support.");
      } else if (response.statusCode == 409) {
        // Conflict - User already exists
        throw Exception(data['message'] ?? "User with this email already exists.");
      } else if (response.statusCode >= 500) {
        // Server errors
        throw Exception("Server error. Please try again later.");
      } else {
        // Other errors
        throw Exception(data['message'] ?? "Registration failed. Please try again.");
      }
    } catch (e) {
      print("REGISTER ERROR: $e");
      // Re-throw the exception so the controller can handle it
      rethrow;
    }
  }

  /// 🔥 LOGIN API with improved error handling
  static Future<UserData?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: $data");

      if (response.statusCode == 200) {
        // Success - return user data
        if (data['data'] != null) {
          return UserData.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? "Login failed. No user data received.");
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - wrong credentials
        throw Exception(data['message'] ?? "Invalid email or password");
      } else if (response.statusCode == 422) {
        // Validation errors
        String errorMessage = data['message'] ?? "Validation failed";
        
        // Extract specific validation errors if available
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final errorStrings = <String>[];
          
          errors.forEach((field, messages) {
            if (messages is List) {
              errorStrings.add('${field.toUpperCase()}: ${messages.join(', ')}');
            } else {
              errorStrings.add('${field.toUpperCase()}: $messages');
            }
          });
          
          if (errorStrings.isNotEmpty) {
            errorMessage = errorStrings.join('\n');
          }
        }
        
        throw Exception(errorMessage);
      } else if (response.statusCode == 403) {
        // Forbidden - Account may be blocked
        throw Exception(data['message'] ?? "Account access forbidden. Please contact support.");
      } else if (response.statusCode == 404) {
        // Not found - User doesn't exist
        throw Exception(data['message'] ?? "Account not found. Please sign up first.");
      } else if (response.statusCode >= 500) {
        // Server errors
        throw Exception("Server error. Please try again later.");
      } else {
        // Other errors
        throw Exception(data['message'] ?? "Login failed. Please try again.");
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
      // Re-throw the exception so the controller can handle it
      rethrow;
    }
  }
}
import 'dart:io';
import 'package:flutter/material.dart';

import '../Models new/register_request_model.dart';
import '../Models new/register_response_model.dart';
import '../Models new/user_model.dart';
import '../service new/auth service/auth_service.dart';

class AuthController extends ChangeNotifier {
  bool isLoading = false;
  
  // Add error tracking
  String? lastError;
  bool hasError = false;

  /// REGISTER with proper error handling
  Future<RegisterResponse?> register({
    required RegisterRequest request,
    required List<File> files,
  }) async {
    try {
      isLoading = true;
      hasError = false;
      lastError = null;
      notifyListeners();

      final res = await AuthService.registerUser(
        request: request,
        files: files,
      );

      return res;
    } catch (e) {
      hasError = true;
      lastError = e.toString();
      print("Registration Controller Error: $e");
      rethrow; // Re-throw to be handled by UI
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// LOGIN with proper error handling
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      hasError = false;
      lastError = null;
      notifyListeners();

      final user = await AuthService.loginUser(
        email: email,
        password: password,
      );

      return user;
    } catch (e) {
      hasError = true;
      lastError = e.toString();
      print("Login Controller Error: $e");
      rethrow; // Re-throw to be handled by UI
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper method to clear errors
  void clearError() {
    hasError = false;
    lastError = null;
    notifyListeners();
  }
}
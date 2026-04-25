

import 'dart:convert';


import 'package:handyman_provider_flutter/Models%20new/registration_data.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:http/http.dart' as http;

class  RegistrationController {
  static Future<RegistrationData> getRegistrationFields() async {
    try {
      final String apiUrl = 'https://ethically-thaw-bok.ngrok-free.dev/api/registration-fields';
      
      print('🌐 Making API call to: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(30.seconds);

      print('📡 Response status code: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ Successfully parsed response');
        return  RegistrationData.fromJson(responseData);
      } else {
        throw Exception('API returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Failed to load registration fields: $e');
    }
  }
}
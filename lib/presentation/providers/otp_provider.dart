import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerified = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isVerified => _isVerified;

  Future<bool> verifyOtp(String otp, String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Backend API call (replace with your actual endpoint)
      final response = await http.post(
        Uri.parse('https://your-api.com/verify-otp'), // Replace with your backend URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'otp': otp,
          'phone': phoneNumber, // Assume phone is passed from signup/login
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _isVerified = true;
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Verification failed';
        }
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
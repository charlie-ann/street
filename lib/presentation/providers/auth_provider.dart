import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:street/core/endpoints.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _username;        // ← NEW: Username added
  String? _avatar;
  double? _walletBalance;
  Timer? _balanceSyncTimer;

  // Getters
  String? get token => _token;
  String? get userId => _userId;
 String? get username => _username ?? 'Player';
  String? get avatar => _avatar;
  double get walletBalance => _walletBalance ?? 0.0;
  bool get isLoggedIn => _token != null && _userId != null;

  // Start real-time balance sync
  void startBalanceSync() {
    _balanceSyncTimer?.cancel();
    _balanceSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_token != null) _fetchLatestBalance();
    });
  }

  void stopBalanceSync() {
    _balanceSyncTimer?.cancel();
  }

  Future<void> _fetchLatestBalance() async {
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.baseUrl}/users/userId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newBalance = (data['walletBalance'] ?? data['balance'] ?? 0.0).toDouble();

        if (newBalance != _walletBalance) {
          _walletBalance = newBalance;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('wallet_balance', newBalance);
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently handle network errors to avoid spam
      if (e.toString().contains('Failed host lookup')) {
        // Server is down, skip this sync
        return;
      }
      debugPrint('Balance sync failed: $e');
    }
  }

  // Set & Save Username
  Future<void> setUsername(String username) async {
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_username', username);
    notifyListeners();
  }

  // Load Username from storage
  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_username');
    notifyListeners();
  }

  // Set & Save User ID
  Future<void> setUserId(String id) async {
    _userId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
    notifyListeners();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    notifyListeners();
  }

  // Token
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    notifyListeners();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    notifyListeners();
  }

  // Wallet Balance
  Future<void> setWalletBalance(double balance) async {
    _walletBalance = balance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wallet_balance', balance);
    startBalanceSync(); // Auto-sync balance
    notifyListeners();
  }

  Future<void> loadWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _walletBalance = prefs.getDouble('wallet_balance');
    startBalanceSync(); // Auto-sync balance
    notifyListeners();
  }

  // Load All User Data at Once (Recommended)
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _username = prefs.getString('user_username');
    _avatar = prefs.getString('user_avatar');
    _walletBalance = prefs.getDouble('wallet_balance');
    if (_token != null) {
      startBalanceSync();
      await _fetchLatestBalance();
    }
    notifyListeners();
  }

  // Load avatar separately if needed
  Future<void> loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    _avatar = prefs.getString('user_avatar');
    notifyListeners();
  }

  // Save All User Data (after login/register)
  Future<void> saveUserData({
    required String token,
    required String userId,
    required String username,
    required double walletBalance,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('auth_token', token),
      prefs.setString('user_id', userId),
      prefs.setString('user_username', username),        // ← Save username
      prefs.setDouble('wallet_balance', walletBalance),
    ]);

    _token = token;
    _userId = userId;
    _username = username;
    _walletBalance = walletBalance;
    notifyListeners();
  }

  // Update only balance (used after deposit)
  Future<void> updateWalletBalance(double newBalance) async {
    _walletBalance = newBalance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wallet_balance', newBalance);
    notifyListeners();
  }

  // Update avatar
  Future<void> updateAvatar(String newAvatar) async {
    _avatar = newAvatar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar', newAvatar);
    notifyListeners();
  }

  // Logout / Clear All
 Future<void> logout() async {
    stopBalanceSync();
    _token = null;
    _userId = null;
    _username = null;
    _avatar = null;
    _walletBalance = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
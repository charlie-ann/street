import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameProvider with ChangeNotifier {
  String _playerName = '';
  int _score = 0;
  double _balance = 124.50; // Add this for user balance (default or load from storage)

  String get playerName => _playerName;
  int get score => _score;
  double get balance => _balance; // Add this getter

  GameProvider() {
    _loadData();
  }

  void updatePlayerName(String name) {
    _playerName = name;
    _saveData();
    notifyListeners();
  }

  void updateScore(int points) {
    _score += points;
    _saveData();
    notifyListeners();
  }

  void updateBalance(double amount) { // Add method to update balance
    _balance += amount;
    _saveData();
    notifyListeners();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _playerName = prefs.getString('playerName') ?? '';
    _score = prefs.getInt('score') ?? 0;
    _balance = prefs.getDouble('balance') ?? 124.50; // Load balance
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('playerName', _playerName);
    prefs.setInt('score', _score);
    prefs.setDouble('balance', _balance);
  }
}
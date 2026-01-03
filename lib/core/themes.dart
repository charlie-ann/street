import 'package:flutter/material.dart';
import 'package:street/core/constants.dart';

final ThemeData streetTheme = ThemeData(
  primarySwatch: Colors.lightBlue,
  scaffoldBackgroundColor: Colors.grey[900],
  textTheme: const TextTheme(
    headlineLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
    labelLarge: TextStyle(color: Colors.white, fontSize: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
    ),
  ),
);
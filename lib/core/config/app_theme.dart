import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    hintColor: Colors.amber,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.grey,
    hintColor: Colors.blueAccent,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
  );
}

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.grey[300],
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blueGrey[700],
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.dark(
        primary: Colors.blueGrey[400]!,
        secondary: Colors.blue[300]!,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[800],
      ),
      cardTheme: CardTheme(
        color: Colors.grey[800],
        shadowColor: Colors.black45,
      ),
    );
  }
}

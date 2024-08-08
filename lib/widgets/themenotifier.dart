import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';

  MaterialColor _themeColor = Colors.cyan;

  MaterialColor get themeColor => _themeColor;

  ThemeNotifier() {
    _loadTheme();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? colorIndex = prefs.getInt(_themeKey);
    if (colorIndex != null) {
      _themeColor = _materialColorFromIndex(colorIndex);
    }
    notifyListeners();
  }

  void setThemeColor(MaterialColor color) async {
    _themeColor = color;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeKey, _materialColorIndex(color));
  }

  // Helper function to convert MaterialColor to index
  int _materialColorIndex(MaterialColor color) {
    switch (color) {
      case Colors.cyan:
        return 0;
      case Colors.deepOrange:
        return 1;
      case Colors.pink:
        return 2;
      case Colors.red:
        return 3;
      case Colors.green:
        return 4;
      case Colors.grey:
        return 5;
      case Colors.yellow:
       return 6;
      case Colors.brown:
       return 7;
      case Colors.indigo:
      return 8;
      case Colors.lightGreen:
      return 9;
      case Colors.deepPurple:
      return 10;
      default:
        return 0; // Default to cyan
    }
  }

  // Helper function to convert index to MaterialColor
  MaterialColor _materialColorFromIndex(int index) {
    switch (index) {
      case 0:
        return Colors.cyan;
      case 1:
        return Colors.deepOrange;
      case 2:
        return Colors.pink;
      case 3:
        return Colors.red;
      case 4:
        return Colors.green;
      case 5:
      return Colors.grey;
      case 6:
      return Colors.yellow;
      case 7:
      return Colors.brown;
      case 8:
      return Colors.indigo;
      case 9:
      return Colors.lightGreen;
      case 10:
      return Colors.deepPurple;
      default:
        return Colors.cyan;
    }
  }
}

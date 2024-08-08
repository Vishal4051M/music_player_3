import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_player_3/widgets/nav_bar.dart'; // Import the ThemeNotifier class
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';

class Themes extends StatefulWidget {
  const Themes({Key? key}) : super(key: key);

  @override
  State<Themes> createState() => _ThemesState();
}

class _ThemesState extends State<Themes> {
  late ThemeNotifier _themeNotifier;
  late MaterialColor _selectedColor;

  @override
  void initState() {
    super.initState();
    _themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    _selectedColor = _themeNotifier.themeColor;
  }

  void _handleColorChange(MaterialColor color) {
    setState(() {
      _selectedColor = color;
      _themeNotifier.setThemeColor(color);
      HapticFeedback.lightImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    final List<MaterialColorOption> colorOptions = [
      MaterialColorOption(materialColor: Colors.cyan, name: 'Cyan'),
      MaterialColorOption(
          materialColor: Colors.deepOrange, name: 'Deep Orange'),
      MaterialColorOption(materialColor: Colors.pink, name: 'Pink'),
      MaterialColorOption(materialColor: Colors.red, name: 'Red'),
      MaterialColorOption(materialColor: Colors.green, name: 'Green'),
      MaterialColorOption(materialColor: Colors.grey, name: 'Grey'),
      MaterialColorOption(materialColor: Colors.yellow, name: 'Yellow'),
      MaterialColorOption(materialColor: Colors.brown, name: 'Brown'),
      MaterialColorOption(materialColor: Colors.indigo, name: 'Indigo'),
      MaterialColorOption(
          materialColor: Colors.lightGreen, name: 'Light Green'),
      MaterialColorOption(
          materialColor: Colors.deepPurple, name: 'Deep Purple'),
    ];

    return Scaffold(
      backgroundColor: globalThemeColor.shade400,
      appBar: AppBar(
        backgroundColor: globalThemeColor.shade400,
        title: const Text(
          'Select Theme Color',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: colorOptions.map((option) {
          return Padding(
            padding: const EdgeInsets.all(5),
            child: RadioListTile<MaterialColor>(
              title: Text(
                option.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: option.materialColor,
              groupValue: _selectedColor,
              onChanged: (color) => _handleColorChange(color!),
              activeColor: Colors.black,
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: const CreateBottomNavigationBar(),
    );
  }
}

class MaterialColorOption {
  final MaterialColor materialColor;
  final String name;

  MaterialColorOption({required this.materialColor, required this.name});
}

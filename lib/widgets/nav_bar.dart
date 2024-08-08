import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:music_player_3/widgets/nav_controller.dart';
import 'package:music_player_3/widgets/mini_player.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';

class CreateBottomNavigationBar extends StatefulWidget {
  const CreateBottomNavigationBar({super.key});

  @override
  State<CreateBottomNavigationBar> createState() =>
      _CreateBottomNavigationBarState();
}

class _CreateBottomNavigationBarState extends State<CreateBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    final NavController navController = Get.find();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
          ),
          child: MiniPlayer(),
        ), // Add the mini player widget
        Stack(
          children: [
            Container(
              height: 60, // Adjust height to match BottomNavigationBar
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    globalThemeColor.shade700,
                    globalThemeColor.shade200
                  ],
                ),
              ),
            ),
            Obx(
              () => BottomNavigationBar(
                currentIndex: navController.selectedIndex.value,
                onTap: (index) {
                  HapticFeedback.selectionClick(); // Add haptic feedback
                  navController.changeTabIndex(index);
                  switch (index) {
                    case 0:
                      Get.toNamed('/');
                      break;
                    case 1:
                      Get.toNamed('/playlist');
                      break;
                    case 2:
                      Get.toNamed('/profile');
                      break;
                    default:
                      Get.toNamed('/');
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_music_rounded),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.black,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors
                    .transparent, // Ensure background is transparent for gradient
                elevation: 0, // Remove shadow
              ),
            ),
          ],
        ),
      ],
    );
  }
}

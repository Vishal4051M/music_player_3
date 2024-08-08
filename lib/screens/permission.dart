import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_player_3/screens/playlist_screen.dart';

class RequestPermissionScreen extends StatefulWidget {
  @override
  _RequestPermissionScreenState createState() =>
      _RequestPermissionScreenState();
}

class _RequestPermissionScreenState extends State<RequestPermissionScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    // Check if permission is already granted
    var status = await Permission.storage.status;

    if (status.isGranted) {
      // Permissions are granted
      Get.off(() => PlaylistScreen());
    } else {
      // Request permission if not granted
      status = await Permission.storage.request();

      if (status.isGranted) {
        // Permission granted after request
        Get.off(() => PlaylistScreen());
      } else {
        // Permission denied, show a message or handle accordingly
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Storage permission is required to access files.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_3/music_provider.dart';
import 'package:music_player_3/screens/LikedSongsScreen.dart';
import 'package:music_player_3/screens/local_file_screen.dart';
import 'package:music_player_3/widgets/nav_bar.dart';
import 'package:music_player_3/widgets/nav_controller.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  void initState() {
    super.initState();

    _requestPermissionsAndLoadSongs();
  }

  Future<void> _requestPermissionsAndLoadSongs() async {
    if (await _requestPermissions()) {
      // Load songs
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission to access storage denied')),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.isGranted ||
        await Permission.audio.isGranted) {
      return true;
    } else {
      if (await Permission.storage.request().isGranted ||
          (await Permission.audio.request().isGranted)) {
        return true;
      } else {
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: globalThemeColor.shade700,
      ),
      backgroundColor: globalThemeColor.shade100,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [globalThemeColor.shade700, globalThemeColor.shade100],
          ),
        ),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(
                Icons.favorite,
                color: Colors.black,
                size: 30,
              ),
              title: const Text(
                'Liked Songs',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LikedSongsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.queue_music,
                color: Colors.black,
                size: 30,
              ),
              title: const Text(
                'Playlists',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlaylistsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.folder,
                color: Colors.black,
                size: 30,
              ),
              title: const Text(
                'Local Files',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LocalFilesScreen()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CreateBottomNavigationBar(),
    );
  }
}

class PlaylistsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: globalThemeColor,
      ),
      body: const Center(
        child: Text('Display playlists here'),
      ),
    );
  }
}

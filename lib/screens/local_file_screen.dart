import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_3/music_provider.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class LocalFilesScreen extends StatefulWidget {
  @override
  _LocalFilesScreenState createState() => _LocalFilesScreenState();
}

class _LocalFilesScreenState extends State<LocalFilesScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndLoadSongs();
  }

  Future<void> _requestPermissionsAndLoadSongs() async {
    if (await _requestPermissions()) {
      _loadSongs();
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

  Future<void> _loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
    );
    setState(() {
      _songs = songs;
    });
  }

  Future<void> _playSong(List<SongModel> songs, int index) async {
    final musicProvider =
        Provider.of<MusicPlayerProvider>(context, listen: false);
    musicProvider.setPlaylistLocal(songs, index);
  }

  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Files'),
        backgroundColor: globalThemeColor,
      ),
      body: _songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? 'Unknown Artist'),
                  onTap: () => _playSong(_songs, index),
                );
              },
            ),
    );
  }
}

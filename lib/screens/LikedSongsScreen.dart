import 'package:flutter/material.dart';
import 'package:music_player_3/music_provider.dart';
import 'package:music_player_3/widgets/nav_bar.dart';
import 'package:music_player_3/widgets/song_liked.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';

class LikedSongsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final likedSongs = Provider.of<MusicPlayerProvider>(context).likedSongs;
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final album = musicPlayerProvider.likedSongsAlbum;

    return Scaffold(
      backgroundColor: globalThemeColor.shade700,
      appBar: AppBar(
        title: const Text(
          'Liked Songs',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: globalThemeColor.shade200,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [globalThemeColor.shade200, globalThemeColor.shade700],
          ),
        ),
        child: likedSongs.isEmpty || album == null
            ? const Center(
                child: Text('No liked songs yet.'),
              )
            : ListView.builder(
                itemCount: likedSongs.length,
                itemBuilder: (context, index) {
                  final song = likedSongs[index];

                  return SongLiked(
                    song: song,
                    coverUrl: 'assets/images/music_note.png',
                    album: album,
                  );
                },
              ),
      ),
      bottomNavigationBar: const CreateBottomNavigationBar(),
    );
  }
}

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/models/song_model.dart';
import 'package:music_player_3/music_provider.dart';
import 'package:provider/provider.dart';

class SongSearch extends StatelessWidget {
  SongSearch({
    Key? key,
    required this.song,
    required this.coverUrl,
    required this.album,
  }) : super(key: key);

  final Song song;
  final String coverUrl;
  final Album album;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final musicPlayerProvider =
            Provider.of<MusicPlayerProvider>(context, listen: false);

        // Play the song
        try {
          final audioSource = AudioSource.uri(
            Uri.parse(song.url),
            tag: MediaItem(
              id: song.title,
              album: song.description,
              title: song.title,
              artUri: Uri.parse(album.coverUrl),
            ),
          );

          await musicPlayerProvider.playSong(
            song.url,
            '${song.title}.mp3',
            audioSource,
            id: song.title,
            title: song.title,
            album: song.description,
            song: song,
            albumModel: album,
          );
        } catch (e) {
          print('Error initializing player: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to play song')),
          );
        }

        // Navigate to the song screen
        Get.toNamed('/song',
            arguments: {'song': song, 'coverUrl': coverUrl, 'album': album});
      },
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  coverUrl,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 0,
                              left: 0,
                            ),
                            child: Text(
                              song.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 0,
                              left: 0,
                            ),
                            child: Text(
                              song.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();

                        final musicPlayerProvider =
                            Provider.of<MusicPlayerProvider>(context,
                                listen: false);

                        // Play the song
                        try {
                          final audioSource = AudioSource.uri(
                            Uri.parse(song.url),
                            tag: MediaItem(
                              id: song.title,
                              album: song.description,
                              title: song.title,
                              artUri: Uri.parse(album.coverUrl),
                            ),
                          );

                          await musicPlayerProvider.playSong(
                            song.url,
                            '${song.title}.mp3',
                            audioSource,
                            id: song.title,
                            albumModel: album,
                            title: song.title,
                            album: song.description,
                            song: song,
                          );
                        } catch (e) {
                          print('Error initializing player: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to play song')),
                          );
                        }

                        // Navigate to the song scree
                        // Close the keyboard
                      },
                      icon: const Icon(
                        Icons.play_circle,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

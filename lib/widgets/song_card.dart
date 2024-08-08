import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:music_player_3/music_provider.dart';
import 'package:provider/provider.dart';
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/models/song_model.dart';

class SongCard extends StatelessWidget {
  SongCard({
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
    final musicPlayerProvider =
        Provider.of<MusicPlayerProvider>(context, listen: false);
    return InkWell(
      onTap: () async {
        print(song.title);
        HapticFeedback.lightImpact();
        Get.toNamed('/song',
            arguments: {'song': song, 'coverUrl': coverUrl, 'album': album});
        // Get the MusicPlayerProvider

        if (song.title == musicPlayerProvider.getCurrentSong()?.title) {
        } else {
          musicPlayerProvider.audioPlayer.stop();
          musicPlayerProvider.setPlaylist(album.songs, song, album);
          // Play the song
          musicPlayerProvider.audioPlayer.play();
        }

        // Navigate to the song screen
      },
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 70,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
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
                            right: 20,
                            left: 20,
                          ),
                          child: Text(
                            song.title,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 20,
                            left: 20,
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

                      if (song.title ==
                          musicPlayerProvider.getCurrentSong()?.title) {
                      } else {
                        musicPlayerProvider.setPlaylist(
                            album.songs, song, album);

                        // Play the song
                        musicPlayerProvider.audioPlayer.play();
                      }
                    },
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

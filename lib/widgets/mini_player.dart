import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_3/globals.dart';
import 'package:music_player_3/music_provider.dart';
import 'package:music_player_3/screens/song_screen.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';
import 'package:music_player_3/music_provider.dart' as music_provider;

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool j = false;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
      _isDragging = true;
    });

    if (details.primaryDelta! > 0) {
      // User is dragging down
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
      });
    }
  }

  void _expandAndNavigate(BuildContext context) {
    final musicPlayerProvider =
        Provider.of<MusicPlayerProvider>(context, listen: false);
    final song = musicPlayerProvider.currentSong;
    final album = musicPlayerProvider.currentAlbum;
    setState(() {
      if (j == false) {
        _dragOffset = MediaQuery.of(context).size.height * 0.2;
      } else {
        _dragOffset = 0;
      }
    });
    Get.to(
      () => const SongScreen(),
      arguments: {
        'song': Provider.of<music_provider.MusicPlayerProvider>(context,
                    listen: false)
                .getCurrentSong() ??
            song,
        'album': musicPlayerProvider
                .likedSongAlbums[musicPlayerProvider.getCurrentSong()] ??
            musicPlayerProvider.currentAlbum,
        'coverUrl': Provider.of<music_provider.MusicPlayerProvider>(context,
                listen: false)
            .currentAlbum!
            .coverUrl
      },
      transition: Transition.topLevel,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onDragEnd(DragEndDetails details, BuildContext context) {
    if (_dragOffset != 0) {
      setState(() {
        _dragOffset = MediaQuery.of(context).size.height * 0.2;
      });
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<music_provider.MusicPlayerProvider>(
      builder: (context, musicPlayerProvider, child) {
        final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
        final currentMediaItem =
            musicPlayerProvider.audioPlayer.sequenceState?.currentSource?.tag;
        final song = musicPlayerProvider.currentSong;
        final album = musicPlayerProvider.currentAlbum;
        final isLoading = musicPlayerProvider.isLoading;

        if (song == null || album == null) {
          return const SizedBox();
        }

        return GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: (details) => _onDragEnd(details, context),
          onTap: () {
            HapticFeedback.mediumImpact();
            if (_dragOffset == 0) {
              j = true;
            } else {
              j = false;
            }
            _expandAndNavigate(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  globalThemeColor.shade400,
                  globalThemeColor.shade300,
                ],
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'albumCover',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: _isDragging ? 150 : 50,
                          height: _isDragging ? 150 : 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              currentMediaItem != null
                                  ? currentMediaItem.artUri.toString()
                                  : song.coverUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_dragOffset !=
                          MediaQuery.of(context).size.height * 0.2) ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: AnimatedOpacity(
                                    opacity: _isDragging ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      currentMediaItem != null
                                          ? currentMediaItem.id
                                          : song.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                              ),
                              AnimatedOpacity(
                                  opacity: _isDragging ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    currentMediaItem != null
                                        ? currentMediaItem.album
                                        : song.description,
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  )),
                            ],
                          ),
                        ),
                        isLoading
                            ? AnimatedOpacity(
                                opacity: _isDragging ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            : AnimatedOpacity(
                                opacity: _isDragging ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: IconButton(
                                  icon: Icon(
                                    musicPlayerProvider.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    if (musicPlayerProvider.isPlaying) {
                                      musicPlayerProvider.pause();
                                    } else if (play_song == true) {
                                      musicPlayerProvider.setPlaylist(
                                          album.songs, song, album);
                                    } else {
                                      musicPlayerProvider.play();
                                    }
                                  },
                                ),
                              ),
                      ] else ...[
                        // Add seek bar and playback control buttons here when expanded
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                currentMediaItem != null
                                    ? currentMediaItem.id
                                    : song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currentMediaItem != null
                                    ? currentMediaItem.album
                                    : song.description,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 5, left: 5, right: 5),
                                child: StreamBuilder<Duration>(
                                  stream: musicPlayerProvider
                                      .audioPlayer.positionStream,
                                  builder: (context, snapshot) {
                                    final position =
                                        musicPlayerProvider.currentPosition ??
                                            Duration.zero;
                                    final duration =
                                        musicPlayerProvider.currentDuration;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: 20,
                                        bottom: 20,
                                        right: 10,
                                        left: 10,
                                      ),
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3.0,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                            disabledThumbRadius: 6,
                                            enabledThumbRadius: 4,
                                          ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                            overlayRadius: 8.0,
                                          ),
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor:
                                              Colors.white.withOpacity(0.3),
                                          thumbColor: globalThemeColor,
                                          overlayColor: Colors.white,
                                        ),
                                        child: Slider(
                                            value:
                                                position.inSeconds.toDouble(),
                                            max: duration.inSeconds.toDouble(),
                                            onChanged: (value) {
                                              HapticFeedback.selectionClick();
                                              musicPlayerProvider.seek(Duration(
                                                  seconds: value.toInt()));
                                            }),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      if (musicPlayerProvider
                                              .audioPlayer.position >
                                          const Duration(seconds: 5)) {
                                        musicPlayerProvider.seek(
                                            musicPlayerProvider
                                                    .audioPlayer.position -
                                                const Duration(seconds: 5));
                                      }
                                    },
                                    onLongPress: () {
                                      HapticFeedback.lightImpact();
                                      musicPlayerProvider.audioPlayer
                                          .seekToPrevious();
                                    },
                                    child: const Icon(
                                      CupertinoIcons.backward_fill,
                                      color: Colors.white,
                                    ),
                                  ),
                                  isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : IconButton(
                                          icon: Icon(
                                            musicPlayerProvider.isPlaying
                                                ? CupertinoIcons.pause_fill
                                                : CupertinoIcons
                                                    .play_arrow_solid,
                                            color: Colors.white,
                                          ),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            if (musicPlayerProvider.isPlaying) {
                                              musicPlayerProvider.pause();
                                            } else if (play_song == true) {
                                              musicPlayerProvider.setPlaylist(
                                                  album.songs, song, album);
                                            } else {
                                              musicPlayerProvider.play();
                                            }
                                          },
                                        ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      musicPlayerProvider.seek(
                                          musicPlayerProvider
                                                  .audioPlayer.position +
                                              const Duration(seconds: 5));
                                    },
                                    onLongPress: () {
                                      HapticFeedback.lightImpact();
                                      musicPlayerProvider.audioPlayer
                                          .seekToNext();
                                    },
                                    child: const Icon(
                                      CupertinoIcons.forward_fill,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 13, left: 8),
                  child: AnimatedOpacity(
                    opacity: _isDragging ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: StreamBuilder<Duration>(
                      stream: musicPlayerProvider.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = musicPlayerProvider.currentDuration;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return LinearProgressIndicator(
                          borderRadius: BorderRadius.circular(8),
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

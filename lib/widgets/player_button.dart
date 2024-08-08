import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_3/globals.dart';
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/music_provider.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:music_player_3/models/song_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerButton extends StatefulWidget {
  const PlayerButton({
    super.key,
    required this.musicProvider,
    required this.album,
    required this.song,
  });

  final MusicPlayerProvider musicProvider;
  final Song song;
  final Album? album;

  @override
  State<PlayerButton> createState() => _PlayerButtonState();
}

class _PlayerButtonState extends State<PlayerButton>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool isLoopingOne = false;
  bool isLoopingAll = false;

  // ValueNotifier to track download state
  final ValueNotifier<bool> _isDownloading = ValueNotifier<bool>(false);
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _audioPlayer = widget.musicProvider.audioPlayer;

    // Initialize loop mode state
    _loadLoopMode();
    widget.musicProvider.onSongComplete = () {
      _audioPlayer.seekToNext();
    };

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _loadLoopMode() async {
    final prefs = await SharedPreferences.getInstance();
    final loopMode = prefs.getString('loopMode') ?? 'off';
    setState(() {
      if (loopMode == 'one') {
        isLoopingOne = true;
        isLoopingAll = false;
        widget.musicProvider.audioPlayer.setLoopMode(LoopMode.one);
      } else if (loopMode == 'all') {
        isLoopingOne = false;
        isLoopingAll = true;
        widget.musicProvider.audioPlayer.setLoopMode(LoopMode.all);
      } else {
        isLoopingOne = false;
        isLoopingAll = false;
        widget.musicProvider.audioPlayer.setLoopMode(LoopMode.off);
      }
    });
  }

  Future<void> _saveLoopMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('loopMode', mode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadFile(String url, String filename) async {
    _isDownloading.value = true;
    try {
      var dir = await getApplicationDocumentsDirectory();
      String savePath = '${dir.path}/$filename';
      await Dio().download(url, savePath);
      print(savePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download completed: $filename')),
      );
    } catch (e) {
      _isDownloading.value = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      _isDownloading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 50,
        right: 10,
        left: 10,
        top: 10,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 30, left: 30, bottom: 30, right: 60),
                child: IgnorePointer(
                  ignoring: h, // Disable pointer events when h is true
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final currentPosition =
                          widget.musicProvider.audioPlayer.position;
                      if (currentPosition > const Duration(seconds: 5)) {
                        widget.musicProvider
                            .seek(currentPosition - const Duration(seconds: 5));
                      }
                    },
                    onLongPress: () async {
                      HapticFeedback.heavyImpact();
                      _audioPlayer.seekToPrevious();
                    },
                    child: const Icon(
                      CupertinoIcons.backward_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              StreamBuilder<PlayerState>(
                stream: widget.musicProvider.audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final playerState = snapshot.data!;
                    final processingState = playerState.processingState;
                    final isPlaying = playerState.playing;

                    return _buildIconContainer(processingState, isPlaying);
                  } else {
                    return _buildIconContainer(null, false);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 30, left: 60, bottom: 30, right: 30),
                child: IgnorePointer(
                  ignoring: h,
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      widget.musicProvider.seek(
                          widget.musicProvider.audioPlayer.position +
                              const Duration(seconds: 5));
                    },
                    onLongPress: () async {
                      HapticFeedback.heavyImpact();
                      _audioPlayer.seekToNext();
                    },
                    child: const Icon(
                      CupertinoIcons.forward_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 70, left: 20),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final uri = widget.song.url;
                    final fileName = '${widget.song.title}.mp3';
                    await _downloadFile(uri, fileName);
                  },
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isDownloading,
                    builder: (context, isDownloading, child) {
                      return isDownloading
                          ? AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Icon(
                                  CupertinoIcons.arrow_down,
                                  color: Color.lerp(Colors.white,
                                      Colors.black38, _controller.value),
                                  size: 36,
                                );
                              },
                            )
                          : const Icon(
                              CupertinoIcons.arrow_down,
                              color: Colors.white,
                              size: 36,
                            );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 70, left: 279, right: 20),
                child: GestureDetector(
                  onTap: () async {
                    h = true;
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isLoopingAll) {
                        isLoopingOne = true;
                        isLoopingAll = false;
                        widget.musicProvider.audioPlayer
                            .setLoopMode(LoopMode.one);
                        _saveLoopMode('one');
                      } else if (isLoopingOne) {
                        isLoopingOne = false;
                        isLoopingAll = false;
                        widget.musicProvider.audioPlayer
                            .setLoopMode(LoopMode.off);
                        _saveLoopMode('off');
                      } else {
                        isLoopingAll = true;
                        widget.musicProvider.audioPlayer
                            .setLoopMode(LoopMode.all);
                        _saveLoopMode('all');
                      }
                    });
                  },
                  child: Icon(
                    isLoopingOne
                        ? CupertinoIcons.repeat_1
                        : (isLoopingAll
                            ? CupertinoIcons.repeat
                            : CupertinoIcons.repeat),
                    color: isLoopingOne
                        ? Colors.black38
                        : isLoopingAll
                            ? Colors.black38
                            : Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(ProcessingState? processingState, bool isPlaying) {
    return Container(
      height: 85,
      width: 85,
      alignment: Alignment.center,
      child: _buildIcon(processingState, isPlaying),
    );
  }

  Widget _buildIcon(ProcessingState? processingState, bool isPlaying) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final song = musicPlayerProvider.currentSong;
    final album = musicPlayerProvider.currentAlbum;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      h = true;
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 4.0,
      );
    } else if (play_song == true) {
      return IconButton(
        key: const ValueKey('play'),
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.musicProvider.setPlaylist(album!.songs, song!, album);
        },
        iconSize: 65,
        icon: const Icon(
          CupertinoIcons.play_arrow_solid,
          color: Colors.white,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
    } else if (processingState == ProcessingState.completed) {
      h = false;
      _audioPlayer.stop();
      _audioPlayer.seek(Duration.zero);
      return IconButton(
        key: const ValueKey('play'),
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.musicProvider.play();
        },
        iconSize: 65,
        icon: const Icon(
          CupertinoIcons.play_arrow_solid,
          color: Colors.white,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
    } else if (!isPlaying) {
      h = false;
      return IconButton(
        key: const ValueKey('play'),
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.musicProvider.play();
        },
        iconSize: 65,
        icon: const Icon(
          CupertinoIcons.play_arrow_solid,
          color: Colors.white,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
    } else {
      h = false;
      return IconButton(
        key: const ValueKey('pause'),
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.musicProvider.pause();
        },
        iconSize: 65,
        icon: const Icon(
          CupertinoIcons.pause_solid,
          color: Colors.white,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
    }
  }
}

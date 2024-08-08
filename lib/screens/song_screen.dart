import 'package:flutter/material.dart';
import 'package:music_player_3/globals.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:music_player_3/music_provider.dart' as music_provider;
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/models/song_model.dart';
import 'package:music_player_3/widgets/player_button.dart';
import 'package:music_player_3/widgets/seekbar.dart' as seekbar_widget;

class SongScreen extends StatefulWidget {
  const SongScreen({Key? key}) : super(key: key);

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Song song;
  late Album? album;
  late String coverUrl;

  late AnimationController _controller;
  late Song currentSong;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final arguments = Get.arguments as Map<String, dynamic>;
    song = arguments['song'];
    album = arguments['album'];
    coverUrl = arguments['coverUrl'];
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    final musicPlayerProvider =
        Provider.of<music_provider.MusicPlayerProvider>(context);
    final currentMediaItem =
        musicPlayerProvider.audioPlayer.sequenceState?.currentSource?.tag;
    bool isLiked;
    if (local_song == false) {
      if (currentMediaItem == null) {
        isLiked = musicPlayerProvider.likedSongs
            .any((likedSong) => likedSong.title == (song.title));
      } else {
        if (currentMediaItem.id != song.title) {
          isLiked = musicPlayerProvider.likedSongs.any((likedSong) =>
              likedSong.title == (musicPlayerProvider.getCurrentSong()?.title));
        } else {
          isLiked = musicPlayerProvider.likedSongs
              .any((likedSong) => likedSong.title == (song.title));
        }
      }
    } else {
      isLiked = false;
    }

    return WillPopScope(
      onWillPop: () async {
        _controller.reverse();
        await Future.delayed(_controller.duration!);
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: globalThemeColor.shade500,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              Get.back();
            }
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      globalThemeColor.shade100,
                      globalThemeColor.shade500,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 100,
                  left: 20,
                  right: 20,
                ),
                child: Hero(
                  tag: 'albumCover',
                  child: AnimatedContainer(
                    duration: _controller.duration!,
                    alignment: AlignmentDirectional.topCenter,
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: DecorationImage(
                        image: currentMediaItem?.artUri != null
                            ? NetworkImage(currentMediaItem!.artUri.toString())
                            : NetworkImage(song.coverUrl) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedOpacity(
                                  opacity: _controller.isAnimating ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: Text(
                                    currentMediaItem != null
                                        ? currentMediaItem.id
                                        : song.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontSize: 29,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  )),
                              const SizedBox(height: 8),
                              Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                    currentMediaItem != null
                                        ? currentMediaItem.album
                                        : song.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: globalThemeColor.shade100,
                                        ),
                                  )),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                musicPlayerProvider.toggleLike(
                                    (musicPlayerProvider.getCurrentSong() ??
                                        song),
                                    album!);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<music_provider.SeekbarData>(
                      stream: musicPlayerProvider.seekbarDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;
                        return seekbar_widget.Seekbar(
                          position: positionData?.position ?? Duration.zero,
                          duration: positionData?.duration ?? Duration.zero,
                          onChanged: (value) {
                            musicPlayerProvider.seek(value);
                          },
                          onChangedEnd: (value) {
                            musicPlayerProvider.seek(value);
                          },
                        );
                      },
                    ),
                    PlayerButton(
                      musicProvider: musicPlayerProvider,
                      song: song,
                      album: album,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

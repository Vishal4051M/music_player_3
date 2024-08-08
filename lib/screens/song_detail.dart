import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/widgets/nav_bar.dart';
import 'package:music_player_3/widgets/song_card.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';

class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({Key? key}) : super(key: key);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 300 && !_showTitle) {
        setState(() {
          _showTitle = true;
        });
      } else if (_scrollController.offset <= 300 && _showTitle) {
        setState(() {
          _showTitle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final album = Get.arguments as Album;
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;

    return Scaffold(
      backgroundColor: globalThemeColor.shade400,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    globalThemeColor.shade400,
                    globalThemeColor.shade400,
                  ]),
            ),
          ),
          _buildBody(context, album),
        ],
      ),
      bottomNavigationBar: const CreateBottomNavigationBar(),
    );
  }

  Widget _buildBody(BuildContext context, Album album) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          backgroundColor: globalThemeColor.shade200,
          expandedHeight: 340,
          pinned: true,
          flexibleSpace: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double maxHeight = constraints.biggest.height;
              double minHeight = kToolbarHeight;
              double expandedHeight = 340;
              double t = (maxHeight - minHeight) / expandedHeight;
              double imageSize = (260 * t).clamp(0, 260.0);
              double opacity = imageSize >= 100 ? 1.0 : 0.0;

              return FlexibleSpaceBar(
                title: _showTitle
                    ? AnimatedOpacity(
                        opacity: 1, // Apply opacity based on image size
                        duration: Duration(milliseconds: 150),
                        child: Text(
                          album.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        globalThemeColor.shade50,
                        globalThemeColor.shade400,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 50,
                      top: 40,
                      left: 0,
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: opacity,
                        duration: Duration(milliseconds: 250),
                        child: Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                spreadRadius: 5,
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(album.coverUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  album.description,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return SongCard(
                song: album.songs[index],
                coverUrl: album.coverUrl,
                album: album,
              );
            },
            childCount: album.songs.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 720, // Ensure space for bottom navigation or controls
          ),
        ),
      ],
    );
  }
}

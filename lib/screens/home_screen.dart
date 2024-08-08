import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/models/song_model.dart';
import 'package:music_player_3/widgets/section_header.dart';
import 'package:music_player_3/widgets/album_card.dart';
import 'package:music_player_3/widgets/nav_bar.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';
import 'search_screen.dart'; // Import the SearchScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();

    futureAlbums = fetchAlbumsFromFirestore();
  }

  Future<List<Album>> fetchAlbumsFromFirestore() async {
    try {
      QuerySnapshot albumSnapshot =
          await FirebaseFirestore.instance.collection('telugu_songs').get();

      List<Album> albums = await Future.wait(
        albumSnapshot.docs.map((doc) async {
          List<Song> songs = [];
          QuerySnapshot songsSnapshot =
              await doc.reference.collection('songs').get();
          for (var songDoc in songsSnapshot.docs) {
            songs.add(Song.fromFirestore(songDoc));
          }
          return Album.fromFirestore(doc);
        }),
      );

      return albums;
    } catch (e) {
      print('Error fetching albums: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [globalThemeColor.shade700, globalThemeColor.shade100],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const _CustomAppBar(),
        bottomNavigationBar: const CreateBottomNavigationBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DiscoverMusic(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextFormField(
                    style: TextStyle(color: globalThemeColor),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: globalThemeColor),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: globalThemeColor,
                        size: 25,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    enabled: false, // Disable the TextField to make it a button
                  ),
                ),
              ),
              FutureBuilder<List<Album>>(
                future: futureAlbums,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<MaterialColor>(
                            globalThemeColor),
                        strokeWidth: 4.0,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No albums available'));
                  } else {
                    return _TrendingMusic(albums: snapshot.data!);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingMusic extends StatelessWidget {
  const _TrendingMusic({
    required this.albums,
  });

  final List<Album> albums;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: SectionHeader(
            title: 'Telugu Songs',
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.21,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: albums.length,
            itemBuilder: (context, index) {
              return AlbumCard(album: albums[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _DiscoverMusic extends StatelessWidget {
  const _DiscoverMusic();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi! Welcome', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 3),
          Text(
            'Your Music,Your Vibe',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Get.toNamed('/themes');
        },
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.settings,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

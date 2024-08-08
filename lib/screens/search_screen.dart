import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_player_3/widgets/album_search.dart';
import 'package:music_player_3/widgets/nav_bar.dart';
import 'package:music_player_3/widgets/song_search.dart';
import 'package:provider/provider.dart';
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/models/song_model.dart';
import 'package:music_player_3/widgets/themenotifier.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Album>> futureAlbumResults;
  late Future<Map<Song, Album>> futureSongResults;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    futureAlbumResults = fetchAlbumResults();
    futureSongResults = fetchSongResults();
  }

  Future<List<Album>> fetchAlbumResults([String query = '']) async {
    try {
      QuerySnapshot albumSnapshot =
          await FirebaseFirestore.instance.collection('telugu_songs').get();

      List<Album> results = [];

      for (var doc in albumSnapshot.docs) {
        List<Song> songs = [];
        QuerySnapshot songsSnapshot =
            await doc.reference.collection('songs').get();

        for (var songDoc in songsSnapshot.docs) {
          if (query.isEmpty ||
              songDoc['title']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase())) {
            songs.add(Song.fromFirestore(songDoc));
          }
        }

        if (query.isEmpty ||
            doc['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase())) {
          results.add(await Album.fromFirestore(doc));
        }
      }

      return results;
    } catch (e) {
      print('Error fetching album results: $e');
      rethrow;
    }
  }

  Future<Map<Song, Album>> fetchSongResults([String query = '']) async {
    try {
      QuerySnapshot albumSnapshot =
          await FirebaseFirestore.instance.collection('telugu_songs').get();

      Map<Song, Album> results = {};

      for (var doc in albumSnapshot.docs) {
        Album album = await Album.fromFirestore(doc);

        QuerySnapshot songsSnapshot =
            await doc.reference.collection('songs').get();

        for (var songDoc in songsSnapshot.docs) {
          if (query.isEmpty ||
              songDoc['title']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase())) {
            Song song = Song.fromFirestore(songDoc);
            results[song] = album;
          }
        }
      }

      return results;
    } catch (e) {
      print('Error fetching song results: $e');
      rethrow;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      futureAlbumResults = fetchAlbumResults(query);
      futureSongResults = fetchSongResults(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;

    return Scaffold(
      backgroundColor: globalThemeColor.shade400,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w400, fontSize: 18),
            border: InputBorder.none,
          ),
        ),
        backgroundColor: globalThemeColor.shade300,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Albums',
              style: TextStyle(
                color: globalThemeColor.shade100,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Album>>(
              future: futureAlbumResults,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<MaterialColor>(
                          globalThemeColor),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No albums found'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var album = snapshot.data![index];
                      return AlbumSearch(album: album);
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Songs',
              style: TextStyle(
                color: globalThemeColor.shade100,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<Song, Album>>(
              future: futureSongResults,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<MaterialColor>(
                          globalThemeColor),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No songs found'));
                } else {
                  var songAlbumMap = snapshot.data!;
                  var songs = songAlbumMap.keys.toList();
                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      var song = songs[index];
                      var album = songAlbumMap[song]!;
                      return SongSearch(
                        song: song,
                        coverUrl: album.coverUrl,
                        album: album,
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CreateBottomNavigationBar(),
    );
  }
}

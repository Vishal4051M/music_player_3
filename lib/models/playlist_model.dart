import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_player_3/models/song_model.dart';

class Album {
  final String title;
  final String description;
  final String coverUrl;
  late List<Song> songs;

  Album({
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.songs,
  });

  // Factory method to convert Firestore document to Album object
  static Future<Album> fromFirestore(DocumentSnapshot doc) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Fetch songs from subcollection "songs"
    QuerySnapshot songsQuery = await doc.reference.collection('songs').get();
    List<Song> songs =
        songsQuery.docs.map((doc) => Song.fromFirestore(doc)).toList();

    return Album(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      songs: songs,
    );
  }

  // Method to convert Album object to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'songs': songs.map((song) => song.toJson()).toList(),
    };
  }

  // Factory method to create an Album object from JSON
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      title: json['title'],
      description: json['description'],
      coverUrl: json['coverUrl'],
      songs: (json['songs'] as List)
          .map((songJson) => Song.fromJson(songJson))
          .toList(),
    );
  }

  // Method to fetch the album containing the given song from Firestore
  static Album? fetchAlbumBySong(Song song) {
    // Synchronous method that uses asynchronous operations internally
    final albumsQuerySnapshot =
        FirebaseFirestore.instance.collection('albums').get();
    albumsQuerySnapshot.then((snapshot) async {
      for (var albumDoc in snapshot.docs) {
        final album = await Album.fromFirestore(albumDoc);
        if (album.songs
            .any((s) => s.title == song.title && s.url == song.url)) {
          return album;
        }
      }
    }).catchError((error) {
      // Handle errors if necessary
      print('Error fetching albums: $error');
      return null;
    });

    return null; // Return null if no album is found containing the song
  }
}

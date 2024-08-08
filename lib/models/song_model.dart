import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String title;
  final String description;
  final String url;
  final String coverUrl;

  Song({
    required this.title,
    required this.description,
    required this.url,
    required this.coverUrl,
  });

  // Factory method to create a Song object from a title
  static Song fromTitle(String title) {
    return Song(
        title: title,
        description: '', // Default or placeholder description
        url: '',
        coverUrl: '' // Default or placeholder URL
        );
  }

  // Factory method to convert Firestore document to Song object
  factory Song.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Song(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
    );
  }

  // Method to convert Song object to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'coverUrl': coverUrl
    };
  }

  // Factory method to create a Song object from JSON
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
        title: json['title'],
        description: json['description'],
        url: json['url'],
        coverUrl: json['coverUrl']);
  }
}

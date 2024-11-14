import 'dart:io';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:music_player_3/models/song_model.dart';
import 'package:music_player_3/models/playlist_model.dart';

class AddSongScreen extends StatefulWidget {
  @override
  _AddSongScreenState createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title, _description, _albumTitle, _language;
  File? _audioFile, _coverFile;
  bool _isLoading = false;

  // Available languages for album categorization
  List<String> languages = ['telugu_songs', 'tamil_songs', 'hindi_songs', 'malayalam_songs', 'english_songs'];

  final Audiotagger _tagger = Audiotagger();

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
      });

      // Extract metadata
      Tag? tag = (await _tagger.readTagsAsMap(path: _audioFile!.path)) as Tag?;
      if (tag != null) {
        setState(() {
          _title = tag.title ?? "Unknown Title";
          _albumTitle = tag.album ?? "Unknown Album";
          _description = tag.artist ?? "Unknown Artist";
        });

        // Extract cover image from metadata if available
        if (tag.artwork != null) {
          _coverFile = File(tag.artwork!);
        }
      }
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _coverFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _addSongToAlbum() async {
    if (_formKey.currentState!.validate() && _audioFile != null && _coverFile != null) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // Upload audio file to Firebase Storage
        final audioFileName = _audioFile!.path.split('/').last;
        final audioStorageRef = FirebaseStorage.instance.ref().child('$_albumTitle/$audioFileName');
        final audioUploadTask = await audioStorageRef.putFile(_audioFile!);
        final audioUrl = await audioUploadTask.ref.getDownloadURL();

        // Upload cover image to Firebase Storage
        final coverFileName = _coverFile!.path.split('/').last;
        final coverStorageRef = FirebaseStorage.instance.ref().child('$_albumTitle/$coverFileName');
        final coverUploadTask = await coverStorageRef.putFile(_coverFile!);
        final coverUrl = await coverUploadTask.ref.getDownloadURL();

        // Create Song object
        Song newSong = Song(
          title: _title!,
          description: _description ?? '',
          url: audioUrl,
          coverUrl: coverUrl,
        );

        // Check if the album already exists in Firestore
        DocumentReference albumRef = FirebaseFirestore.instance
            .collection(_language!)
            .doc(_albumTitle);
        
        DocumentSnapshot albumSnapshot = await albumRef.get();

        if (albumSnapshot.exists) {
          // If album exists, add song to album's "songs" sub-collection
          await albumRef.collection('songs').add(newSong.toJson());
        } else {
          // If album doesn't exist, create new Album and add song
          Album newAlbum = Album(
            title: _albumTitle!,
            description: 'Description of $_albumTitle', // Adjust as needed
            coverUrl: coverUrl,
            songs: [newSong],
          );

          await albumRef.set({
            'title': newAlbum.title,
            'description': newAlbum.description,
            'coverUrl': newAlbum.coverUrl,
          });

          // Add song to new album's "songs" sub-collection
          await albumRef.collection('songs').add(newSong.toJson());
        }

        // Reset form and state
        _formKey.currentState!.reset();
        setState(() {
          _audioFile = null;
          _coverFile = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Song added successfully to $_albumTitle!")),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add song: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields and select audio and cover image")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Song')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: "Song Title"),
                validator: (value) => value!.isEmpty ? "Enter song title" : null,
                onSaved: (value) => _title = value,
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: "Description"),
                onSaved: (value) => _description = value,
              ),
              TextFormField(
                initialValue: _albumTitle,
                decoration: InputDecoration(labelText: "Album Title"),
                validator: (value) => value!.isEmpty ? "Enter album title" : null,
                onSaved: (value) => _albumTitle = value,
              ),
              DropdownButtonFormField<String>(
                value: _language,
                hint: Text('Select Language'),
                onChanged: (value) {
                  setState(() {
                    _language = value!;
                  });
                },
                items: languages.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickAudioFile,
                child: Text(_audioFile == null ? "Pick Audio File" : "Audio File Selected"),
              ),
              ElevatedButton(
                onPressed: _pickCoverImage,
                child: Text(_coverFile == null ? "Pick Cover Image" : "Cover Image Selected"),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addSongToAlbum,
                      child: Text("Add Song"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_3/globals.dart';
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/models/song_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Song> _likedSongs = [];
  final List<String> _coverUrl = [];
  List<SongModel> _playlist = [];
  SongModel? _currenTSong;
  Map<Song, Album> likedSongAlbums = {};
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  String _currentSongId = '';
  Song? _currentSong;
  SongModel? get currenTSong => _currenTSong;
  Album? _currentAlbum;
  bool _isLoading = false;
  VoidCallback? onSongComplete;
  List<Song> get likedSongs => _likedSongs;
  List<String> get coverUrl => _coverUrl;
  Album? _likedSongsAlbum;
  bool _isInitialized = false;
  Album? get likedSongsAlbum => _likedSongsAlbum;

  MusicPlayerProvider() {
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _handlePositionDurationDifference();
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _currentDuration = duration ?? Duration.zero;
      _handlePositionDurationDifference();
      notifyListeners();
    });
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState?.currentSource?.tag != null) {
        final currentMediaItem = sequenceState!.currentSource!.tag as MediaItem;
        if (currentMediaItem.id != _currentSong!.title) {
          _saveCurrentSong();
        }
      }
    });
    loadCurrentSong();
    _loadLikedSongs();
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  String get currentSongId => _currentSongId;
  Song? get currentSong => _currentSong;
  Album? get currentAlbum => _currentAlbum;
  bool get isLoading => _isLoading;
  bool get isIntialized => _isInitialized;

  Future<void> setPlaylist(
      List<Song> songs, Song currentSong, Album currentAlbum) async {
    local_song = false;
    play_song = false;
    List<AudioSource> audioSources = [];
    for (var song in songs) {
      final fileExists = await _checkFileExists('${song.title}.mp3');
      if (fileExists) {
        final filePath = await _getLocalFilePath('${song.title}.mp3');
        audioSources.add(
          AudioSource.uri(
            Uri.file(filePath),
            tag: MediaItem(
              id: song.title,
              album: song.description,
              title: song.title,
              artUri: Uri.parse(song
                  .coverUrl), // Use the cover URL from the liked song's album if available, otherwise use the current album's cover URL
            ),
          ),
        );
      } else {
        audioSources.add(
          AudioSource.uri(
            Uri.parse(song.url),
            tag: MediaItem(
              id: song.title,
              album: song.description,
              title: song.title,
              artUri: Uri.parse(song.coverUrl), // Same logic here
            ),
          ),
        );
      }
    }

    final currentIndex = songs.indexWhere((song) =>
        song.title == currentSong.title && song.url == currentSong.url);

    if (currentIndex == -1 || currentIndex >= audioSources.length) {
      // Handle invalid current song index
      print('Invalid current song index: $currentIndex');
      return;
    }

    final playlist = ConcatenatingAudioSource(children: audioSources);

    _isLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.setAudioSource(playlist,
          initialIndex: currentIndex, preload: true);
      _audioPlayer.seek(Duration.zero);
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _audioPlayer.play();
    } catch (e) {
      print('Error setting playlist: $e');
    } finally {
      _currentSong = currentSong;
      _currentAlbum = currentAlbum;
      _isLoading = false;
      _saveCurrentSong();
      notifyListeners();
    }
  }

  Future<void> setPlaylistLocal(List<SongModel> songs, int index) async {
    List<AudioSource> audioSources = [];
    for (var song in songs) {
      // Fetch artwork for the song
      Uint8List? artwork;
      try {
        artwork = await OnAudioQuery().queryArtwork(
          song.id,
          ArtworkType.AUDIO,
        );
      } catch (e) {
        print('Error fetching artwork for song ${song.title}: $e');
      }

      final artUri = artwork != null
          ? Uri.dataFromBytes(artwork, mimeType: 'image/jpeg')
          : null;

      audioSources.add(
        AudioSource.uri(
          Uri.file(song.data),
          tag: MediaItem(
            id: song.title,
            album: song.album ?? 'Unknown Album',
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            duration: Duration(milliseconds: song.duration ?? 0),
            artUri: artUri,
          ),
        ),
      );
    }

    final currentIndex = index;

    if (currentIndex == -1 || currentIndex >= audioSources.length) {
      print('Invalid current song index: $currentIndex');
      return;
    }

    final playlist = ConcatenatingAudioSource(children: audioSources);

    _isLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: currentIndex,
        preload: true,
      );
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } catch (e) {
      print('Error setting playlist: $e');
    } finally {
      _playlist = songs;
      _currentAlbum = Album(
        title: 'Local Songs',
        coverUrl: '', // Provide a default cover URL or handle it appropriately
        songs: songs
            .map((song) => Song(
                  title: song.title,
                  description: song.album ?? 'Unknown Album',
                  url: song.data,
                  coverUrl:
                      'assets/images/music_note.png', // Provide a default cover URL or handle it appropriately
                ))
            .toList(),
        description: 'Local songs from device',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAudioSourceOnline(AudioSource source,
      {required String currentSongId}) async {
    if (_currentSongId == currentSongId && _currentPosition != Duration.zero) {
      // Do not reinitialize if the same song is already playing
      return;
    }

    _currentSongId = currentSongId;
    _isLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.setAudioSource(source, preload: true);
      _audioPlayer.seek(Duration.zero);
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _audioPlayer.play();
    } catch (e) {
      print('Error setting audio source: $e');
    } finally {
      _currentAlbum = null;
      _currentSong = null;
      _isLoading = false;
      _saveCurrentSong();
      notifyListeners();
    }
  }

  Future<void> setLocalAudioSource(String filePath,
      {required String currentSongId,
      required String id,
      required String album,
      required String title,
      required Album albums}) async {
    if (_currentSongId == currentSongId && _currentPosition != Duration.zero) {
      // Do not reinitialize if the same song is already playing
      return;
    }

    print('Setting local audio source with filePath: $filePath');
    final file = File(filePath);
    if (!file.existsSync()) {
      print('File does not exist at path: $filePath');
      return;
    }

    _currentSongId = currentSongId;
    _isLoading = true;
    notifyListeners();

    try {
      final mediaItem = MediaItem(
        id: id,
        album: album,
        title: title,
        artUri: Uri.parse(
            albums.coverUrl), // Add the appropriate art URI if available
      );

      final audioSource = AudioSource.uri(
        Uri.file(filePath),
        tag: mediaItem,
      );

      await _audioPlayer.setAudioSource(audioSource, preload: true);
      _audioPlayer.seek(Duration.zero);
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _audioPlayer.play();
    } catch (e) {
      print('Error setting local audio source: $e');
    } finally {
      _isLoading = false;
      _saveCurrentSong();
      notifyListeners();
    }
  }

  Future<void> setPlaylistAndPlay(List<SongModel> songs, int index) async {
    _playlist = songs;
    _currenTSong = songs[index];
    print("bYe");
    List<AudioSource> audioSources = songs.map((song) {
      return AudioSource.uri(Uri.parse(song.uri!));
    }).toList();

    final playlist = ConcatenatingAudioSource(children: audioSources);

    _isLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.setAudioSource(playlist, initialIndex: index);
      print("hii");
      _audioPlayer.play();
    } catch (e) {
      print('Error setting playlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playSong(String url, String filename, AudioSource source,
      {required String id,
      required String album,
      required String title,
      required Song song,
      required Album albumModel}) async {
    _isLoading = true;
    notifyListeners();
    local_song = false;
    final fileExists = await _checkFileExists(filename);
    if (fileExists) {
      final filePath = await _getLocalFilePath(filename);
      await setLocalAudioSource(filePath,
          currentSongId: filename,
          id: id,
          album: album,
          title: title,
          albums: albumModel);
    } else {
      await setAudioSourceOnline(source, currentSongId: filename);
    }
    _currentSong = song;
    _currentAlbum = albumModel;
    _isLoading = false;
    _saveCurrentSong();
    notifyListeners();
  }

  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();
  void seek(Duration position) => _audioPlayer.seek(position);
  bool get isPlaying => _audioPlayer.playing;

  Stream<SeekbarData> get seekbarDataStream =>
      Rx.combineLatest2<Duration, Duration?, SeekbarData>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        (position, duration) =>
            SeekbarData(position, duration ?? Duration.zero),
      );

  Future<String> _getLocalFilePath(String filename) async {
    var dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$filename';
  }

  Future<File> _getLocalFile(String filename) async {
    final filePath = await _getLocalFilePath(filename);
    return File(filePath);
  }

  Future<bool> _checkFileExists(String filename) async {
    final file = await _getLocalFile(filename);
    final exists = await file.exists();
    print('Checking if file exists at ${file.path}: $exists');
    return exists;
  }

  void updateTrack(int offset) async {
    await _audioPlayer.seekToNext();
    if (_currentSong != null) {
      await _updateCurrentAlbum(_currentSong!);
    }
    _saveCurrentSong();
  }

  int? getCurrentSongIndex() {
    final currentMediaItem = _audioPlayer.sequenceState?.currentSource?.tag;
    if (currentMediaItem is MediaItem &&
        currentAlbum != null &&
        local_song == false) {
      return currentAlbum!.songs
          .indexWhere((song) => song.title == currentMediaItem.id);
    }
    return null;
  }

  void createLikedSongsAlbum() {
    if (_likedSongs.isEmpty) return;

    _likedSongsAlbum = Album(
      title: 'Liked Songs',
      coverUrl: '', // Provide a default cover URL or handle it appropriately.
      songs: List.from(_likedSongs),
      description: 'Liked songs',
    );

    notifyListeners();
  }

  Song? getCurrentSong() {
    final currentMediaItem = _audioPlayer.sequenceState?.currentSource?.tag;
    if (currentMediaItem is MediaItem && currentAlbum != null) {
      int index = currentAlbum!.songs
          .indexWhere((song) => song.title == currentMediaItem.id);
      return currentAlbum?.songs[index];
    }
    return null;
  }

  void toggleLike(Song? song, Album album) {
    if (likedSongs.any((likedSong) => likedSong.title == song!.title)) {
      Song matchedSong = likedSongs.firstWhere(
        (likedSong) => likedSong.title == song!.title,
        // This will return null if no match is found
      );
      removeFromLikedSongs(matchedSong);
    } else {
      addToLikedSongs(song!, album);
    }
  }

  void addToLikedSongs(Song song, Album album) {
    _likedSongs.add(song);
    likedSongAlbums[song] = album;
    createLikedSongsAlbum();
    _saveLikedSongs(); // Save liked songs to local storage
    notifyListeners();
  }

  void removeFromLikedSongs(Song song) {
    _likedSongs.remove(song);
    createLikedSongsAlbum();
    _saveLikedSongs(); // Save liked songs to local storage
    notifyListeners();
  }

  void _handlePositionDurationDifference() {
    final difference = _currentDuration - _currentPosition;

    if (difference <= Duration(milliseconds: 1) &&
        _currentDuration != Duration.zero &&
        _currentPosition >= Duration.zero) {
      if (onSongComplete != null) {
        updateTrack(1);
        a = true;
      }
    }
  }

  Future<void> _saveCurrentSong() async {
    if (_currentSong != null) {
      _currentSong = getCurrentSong() ?? _currentSong;
      final prefs = await SharedPreferences.getInstance();
      final currentSongData = jsonEncode(_currentSong!.toJson());
      final currentAlbumData =
          _currentAlbum != null ? jsonEncode(_currentAlbum!.toJson()) : null;

      await prefs.setString('current_song', currentSongData);
      if (currentAlbumData != null) {
        await prefs.setString('current_album', currentAlbumData);
      }
    }
  }

  Future<void> loadCurrentSong() async {
    final prefs = await SharedPreferences.getInstance();
    final currentSongData = prefs.getString('current_song');
    final currentAlbumData = prefs.getString('current_album');
    final currentPosition = prefs.getInt('current_position') ?? 0;
    final currentDuration = prefs.getInt('current_duration') ?? 0;
    print('Loading current song and album from shared preferences...');
    print('Current song data: $currentDuration');
    print('Current album data: $currentAlbumData');

    if (currentSongData != null) {
      _currentSong = Song.fromJson(jsonDecode(currentSongData));
      print('Current song loaded: ${_currentSong!.title}');
    } else {
      print('No current song data found.');
    }

    if (currentAlbumData != null) {
      _currentAlbum = Album.fromJson(jsonDecode(currentAlbumData));
      print('Current album loaded: ${_currentAlbum!.title}');
    } else {
      print('No current album data found.');
    }

    _currentPosition = Duration(milliseconds: currentPosition);
    _currentDuration = Duration(milliseconds: currentDuration);

    play_song = true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _updateCurrentAlbum(Song currentSong) async {
    final album = await Album.fetchAlbumBySong(currentSong);
    if (album != null) {
      _currentAlbum = album;
    }
  }

  Future<void> _saveLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final likedSongsJson =
        jsonEncode(_likedSongs.map((song) => song.toJson()).toList());
    prefs.setString('likedSongs', likedSongsJson);
  }

  Future<void> _saveCurrentPositionAndDuration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_position', _currentPosition.inMilliseconds);
    await prefs.setInt('current_duration', _currentDuration.inMilliseconds);
  }

  Future<void> _loadLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final likedSongsJson = prefs.getString('likedSongs');

    if (likedSongsJson != null) {
      final List<dynamic> likedSongsList = jsonDecode(likedSongsJson);
      _likedSongs.clear();
      likedSongsList.forEach((songJson) {
        final song = Song.fromJson(songJson);
        _likedSongs.add(song);
      });
      createLikedSongsAlbum();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _saveCurrentSong();
    _saveCurrentPositionAndDuration();

    _audioPlayer.dispose();
    super.dispose();
  }
}

class SeekbarData {
  final Duration position;
  final Duration duration;

  SeekbarData(this.position, this.duration);
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart'; // Import this for HapticFeedback
import 'package:music_player_3/models/playlist_model.dart';
import 'package:music_player_3/screens/song_detail.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    // Add this line
  });

  final Album album;
  // Add this line

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact(); // Add haptic feedback
        Get.to(
          () => AlbumDetailScreen(),
          arguments: album,
        );
      },
      highlightColor: Colors.transparent, // Remove highlight effect
      splashColor: Colors.transparent, // Remove splash effect
      child: Container(
        margin: const EdgeInsets.only(
          left: 20,
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(
                    album.coverUrl, // Use coverUrl here
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

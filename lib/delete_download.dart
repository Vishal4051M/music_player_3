import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> deleteAllItemsInDirectory(String path) async {
  final dir = Directory(path);
  try {
    if (await dir.exists()) {
      await for (var entity in dir.list(recursive: false)) {
        if (entity is File) {
          await entity.delete();
          print('File deleted: ${entity.path}');
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
          print('Directory deleted: ${entity.path}');
        }
      }
      print('All items deleted in directory: $path');
    } else {
      print('Directory not found: $path');
    }
  } catch (e) {
    print('Error deleting items in directory: $e');
  }
}

Future<void> clearAppDocumentsDirectory() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    await deleteAllItemsInDirectory(dir.path);
  } catch (e) {
    print('Error clearing documents directory: $e');
  }
}

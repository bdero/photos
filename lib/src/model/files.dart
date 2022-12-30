import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';

mixin FilesBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late FilesBinding _instance;
  static FilesBinding get instance => _instance;

  late File _photosFile;
  File get photosFile => _photosFile;

  late File _videosFile;
  File get videosFile => _videosFile;

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;

    FileSystem fs = const LocalFileSystem();
    Directory documentsDirectory;
    try {
      documentsDirectory = fs.directory(await getApplicationDocumentsDirectory()).absolute;
    } catch (error, stack) {
      debugPrint('Error getting application documents directory: $error\n$stack');
      fs = MemoryFileSystem();
      documentsDirectory = fs.directory('documents')..createSync();
    }
    _photosFile = documentsDirectory.childFile('photos');
    _videosFile = documentsDirectory.childFile('videos');
  }

  Future<List<File>> saveFilesToDownloads() async {
    const FileSystem fs = LocalFileSystem();
    io.Directory? rawDir;
    try {
      rawDir = await getDownloadsDirectory();
    } on UnsupportedError {
      // Fallthrough
    }
    rawDir ??= await getTemporaryDirectory();
    final Directory baseDir = fs.directory(rawDir);
    final List<File> copies = <File>[];
    if (photosFile.existsSync()) {
      final File photosFileCopy = baseDir.childFile(photosFile.basename);
      await photosFile.copy(photosFileCopy.path);
      copies.add(photosFileCopy);
    }
    if (videosFile.existsSync()) {
      final File videosFileCopy = baseDir.childFile(videosFile.basename);
      await videosFile.copy(videosFileCopy.path);
      copies.add(videosFileCopy);
    }
    return copies;
  }
}

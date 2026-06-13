import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/repositories/media_store.dart';

/// [MediaStore] backed by the app's local filesystem.
///
/// Files live under `<appSupport>/decko_media/<deckId>/<fileName>`. Per-deck
/// folders prevent filename collisions between decks and make deletion a single
/// recursive remove. [baseDir] is injectable so tests can use a temp directory
/// instead of `path_provider` (DEC-014).
class FileMediaStore implements MediaStore {
  // ignore: prefer_initializing_formals
  const FileMediaStore({Directory? baseDir}) : _baseDir = baseDir;

  final Directory? _baseDir;

  static const String _root = 'decko_media';

  Future<Directory> _deckDir(String deckId, {bool create = false}) async {
    final Directory base = _baseDir ?? await getApplicationSupportDirectory();
    final Directory dir =
        Directory('${base.path}/$_root/${_safe(deckId)}');
    if (create) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<void> saveMedia(
      String deckId, String fileName, Uint8List bytes) async {
    final Directory dir = await _deckDir(deckId, create: true);
    await File('${dir.path}/${_safe(fileName)}').writeAsBytes(bytes);
  }

  @override
  Future<String?> resolveMedia(String deckId, String fileName) async {
    final Directory dir = await _deckDir(deckId);
    final String path = '${dir.path}/${_safe(fileName)}';
    return File(path).existsSync() ? path : null;
  }

  @override
  Future<void> deleteMediaForDeck(String deckId) async {
    final Directory dir = await _deckDir(deckId);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Collapses path separators so a media name can't escape its deck folder.
  String _safe(String name) =>
      name.replaceAll(RegExp(r'[\\/]+'), '_').replaceAll('..', '_');
}

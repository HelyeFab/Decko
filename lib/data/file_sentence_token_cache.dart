// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/repositories/sentence_token_cache.dart';
import '../domain/sentence_builder/cube_token.dart';

/// [SentenceTokenCache] backed by one JSON file per deck on local disk
/// (`<appSupport>/decko_tokens/<deckId>.json`). Kept off `shared_preferences`
/// because a large deck can cache many tokenized sentences (MVP_016).
/// [baseDir] is injectable for tests.
class FileSentenceTokenCache implements SentenceTokenCache {
  const FileSentenceTokenCache({Directory? baseDir}) : _baseDir = baseDir;

  final Directory? _baseDir;

  static const String _root = 'decko_tokens';

  Future<File> _file(String deckId, {bool create = false}) async {
    final Directory base = _baseDir ?? await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/$_root');
    if (create) await dir.create(recursive: true);
    return File('${dir.path}/${_safe(deckId)}.json');
  }

  @override
  Future<Map<String, CachedTokenization>> load(String deckId) async {
    final File f = await _file(deckId);
    if (!f.existsSync()) return <String, CachedTokenization>{};
    try {
      final Map<String, dynamic> map =
          jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return map.map((String itemId, dynamic v) {
        final Map<String, dynamic> e = (v as Map).cast<String, dynamic>();
        return MapEntry<String, CachedTokenization>(
          itemId,
          CachedTokenization(
            sentence: e['sentence'] as String,
            tokens: (e['tokens'] as List<dynamic>)
                .map((dynamic t) =>
                    CubeToken.fromJson((t as Map).cast<String, dynamic>()))
                .toList(),
          ),
        );
      });
    } catch (_) {
      return <String, CachedTokenization>{};
    }
  }

  @override
  Future<void> save(
      String deckId, Map<String, CachedTokenization> entries) async {
    if (entries.isEmpty) return;
    final Map<String, CachedTokenization> merged = await load(deckId)
      ..addAll(entries);
    final File f = await _file(deckId, create: true);
    await f.writeAsString(jsonEncode(merged.map(
      (String itemId, CachedTokenization c) => MapEntry<String, dynamic>(
        itemId,
        <String, dynamic>{
          'sentence': c.sentence,
          'tokens': c.tokens.map((CubeToken t) => t.toJson()).toList(),
        },
      ),
    )));
  }

  @override
  Future<void> clear(String deckId) async {
    final File f = await _file(deckId);
    if (f.existsSync()) await f.delete();
  }

  String _safe(String name) =>
      name.replaceAll(RegExp(r'[\\/]+'), '_').replaceAll('..', '_');
}

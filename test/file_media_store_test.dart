import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/file_media_store.dart';

void main() {
  test('FileMediaStore saves, resolves, and deletes per deck', () async {
    final Directory tmp =
        Directory.systemTemp.createTempSync('decko_media_test');
    addTearDown(() => tmp.existsSync() ? tmp.deleteSync(recursive: true) : null);
    final FileMediaStore store = FileMediaStore(baseDir: tmp);

    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    await store.saveMedia('deck-a', 'word_101.wav', bytes);

    final String? path = await store.resolveMedia('deck-a', 'word_101.wav');
    expect(path, isNotNull);
    expect(File(path!).readAsBytesSync(), bytes);

    // Missing file resolves to null.
    expect(await store.resolveMedia('deck-a', 'nope.mp3'), isNull);
    // Media is scoped per deck.
    expect(await store.resolveMedia('deck-b', 'word_101.wav'), isNull);

    await store.deleteMediaForDeck('deck-a');
    expect(await store.resolveMedia('deck-a', 'word_101.wav'), isNull);
  });
}

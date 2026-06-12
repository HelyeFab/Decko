import 'package:flutter_test/flutter_test.dart';

import 'package:decko/core/widgets/furigana_text.dart';

void main() {
  test('parses bracket furigana into base/reading tokens', () {
    final List<FuriToken> t = parseFurigana('今度[こんど]誘[さそ]うね。');

    expect(t.map((FuriToken x) => x.base).toList(),
        <String>['今度', '誘', 'うね。']);
    expect(t.map((FuriToken x) => x.reading).toList(),
        <String?>['こんど', 'さそ', null]);

    // Base-only join reconstructs the plain sentence (furigana toggled off).
    expect(t.map((FuriToken x) => x.base).join(), '今度誘うね。');
  });

  test('splits a leading plain run from the kanji base', () {
    // Reading applies only to the trailing kanji, not the preceding kana.
    final List<FuriToken> t = parseFurigana('に誘[さそ]う');
    expect(t.map((FuriToken x) => x.base).toList(), <String>['に', '誘', 'う']);
    expect(t[1].reading, 'さそ');
  });

  test('plain text yields a single reading-less token', () {
    final List<FuriToken> t = parseFurigana('to invite');
    expect(t, hasLength(1));
    expect(t.single.reading, isNull);
  });
}

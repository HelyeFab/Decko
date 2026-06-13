import 'package:flutter_test/flutter_test.dart';

import 'package:decko/core/content/anki_content.dart';

void main() {
  test('parses text, audio and image segments in order', () {
    final List<AnkiSegment> s = parseAnkiContent(
        '会社[かいしゃ] [sound:word.mp3] <img src="pic.jpg">');

    expect(s, hasLength(3));
    expect((s[0] as TextSegment).text, '会社[かいしゃ]');
    expect((s[1] as AudioSegment).fileName, 'word.mp3');
    expect((s[2] as ImageSegment).fileName, 'pic.jpg');
  });

  test('handles single-quoted and self-closing img tags', () {
    expect((parseAnkiContent("<img src='a.png' />").single as ImageSegment)
        .fileName, 'a.png');
  });

  test('counts and strips media', () {
    const String field = 'word [sound:a.mp3] more [sound:b.mp3] <img src="c.jpg">';
    expect(countAudioRefs(field), 2);
    expect(countImageRefs(field), 1);
    expect(stripMedia(field), 'word more');
  });

  test('normalised media markers are extractable', () {
    expect(mediaMarkers('x [sound:a.mp3] <img src="c.jpg" />'),
        <String>['[sound:a.mp3]', '<img src="c.jpg">']);
  });

  test('plain text is a single text segment', () {
    final List<AnkiSegment> s = parseAnkiContent('just text');
    expect(s.single, isA<TextSegment>());
  });
}

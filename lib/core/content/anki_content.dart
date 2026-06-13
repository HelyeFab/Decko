/// A parsed piece of card content: plain text (which may carry furigana), an
/// audio reference, or an image reference.
sealed class AnkiSegment {
  const AnkiSegment();
}

/// Text that may contain furigana bracket notation (`漢字[かな]`).
class TextSegment extends AnkiSegment {
  const TextSegment(this.text);
  final String text;
}

/// An `[sound:file]` reference.
class AudioSegment extends AnkiSegment {
  const AudioSegment(this.fileName);
  final String fileName;
}

/// An `<img src="file">` reference.
class ImageSegment extends AnkiSegment {
  const ImageSegment(this.fileName);
  final String fileName;
}

final RegExp _mediaToken = RegExp(
  r'\[sound:([^\]]+)\]|<img[^>]*\bsrc\s*=\s*["' "'" r']([^"' "'" r']+)["' "'" r'][^>]*>',
  caseSensitive: false,
);

final RegExp _soundOnly = RegExp(r'\[sound:([^\]]+)\]', caseSensitive: false);
final RegExp _imgOnly =
    RegExp(r'<img[^>]*\bsrc\s*=\s*["' "'" r']([^"' "'" r']+)["' "'" r'][^>]*>',
        caseSensitive: false);

/// Splits an Anki field into ordered text / audio / image segments.
List<AnkiSegment> parseAnkiContent(String field) {
  final List<AnkiSegment> out = <AnkiSegment>[];
  int last = 0;
  for (final Match m in _mediaToken.allMatches(field)) {
    if (m.start > last) {
      final String text = field.substring(last, m.start).trim();
      if (text.isNotEmpty) out.add(TextSegment(text));
    }
    final String? sound = m.group(1);
    if (sound != null) {
      out.add(AudioSegment(sound.trim()));
    } else {
      out.add(ImageSegment(m.group(2)!.trim()));
    }
    last = m.end;
  }
  if (last < field.length) {
    final String text = field.substring(last).trim();
    if (text.isNotEmpty) out.add(TextSegment(text));
  }
  return out;
}

/// All media filenames referenced in [field], audio then image, in order.
List<String> mediaFileNames(String field) => <String>[
      for (final Match m in _mediaToken.allMatches(field))
        (m.group(1) ?? m.group(2)!).trim(),
    ];

/// The normalised media markers (`[sound:x]` / `<img src="x">`) in [field].
List<String> mediaMarkers(String field) => <String>[
      for (final Match m in _mediaToken.allMatches(field))
        m.group(1) != null
            ? '[sound:${m.group(1)!.trim()}]'
            : '<img src="${m.group(2)!.trim()}">',
    ];

/// [field] with media markers removed (for text-only checks/display).
String stripMedia(String field) => field
    .replaceAll(_soundOnly, '')
    .replaceAll(_imgOnly, '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int countAudioRefs(String field) => _soundOnly.allMatches(field).length;
int countImageRefs(String field) => _imgOnly.allMatches(field).length;

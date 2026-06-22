import 'cube_token.dart';

/// One draggable word tile of a sentence-builder round. Carries its surface
/// text plus furigana segments for rendering readings. Framework-light.
class SentenceBuilderToken {
  const SentenceBuilderToken({
    required this.text,
    required this.position,
    this.furigana = const <FuriganaSegment>[],
  });

  /// The visible surface word.
  final String text;

  /// The correct 0-based position of this token in the sentence.
  final int position;

  /// Per-span furigana for rendering readings above the tile.
  final List<FuriganaSegment> furigana;

  @override
  bool operator ==(Object other) =>
      other is SentenceBuilderToken &&
      other.text == text &&
      other.position == position;

  @override
  int get hashCode => Object.hash(text, position);

  @override
  String toString() => 'SentenceBuilderToken($position: "$text")';
}

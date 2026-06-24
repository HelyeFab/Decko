import 'learning_item.dart';
import 'sentence_builder/sentence_text.dart';

/// The vocabulary fields a practice mode needs from a card (MVP_025): the
/// expression (the word), its meaning, and its reading.
class CardFields {
  const CardFields({
    required this.expression,
    required this.meaning,
    this.reading,
  });

  /// The word/expression — cleaned, may be empty.
  final String expression;

  /// The meaning — cleaned, may be empty.
  final String meaning;

  /// The kana reading, or null when there isn't a distinct one.
  final String? reading;
}

/// Extracts a card's vocabulary fields, robust to two common note shapes:
///
/// 1. **Expression on the front** (the usual case): front = word, back = meaning.
/// 2. **Media-only front** (e.g. listening cards: front = `[sound:…] <img>`):
///    the word + meaning are packed into the back as `expression\nmeaning`.
///
/// Text is cleaned of media markers / HTML so practice modes get plain values.
CardFields cardFieldsOf(LearningItem item) {
  final String front = cleanSentence(item.front).trim();
  final String reading = cleanSentence(item.reading ?? '').trim();
  final String? readingOrNull = reading.isEmpty ? null : reading;

  if (front.isNotEmpty) {
    return CardFields(
      expression: front,
      meaning: cleanSentence(item.back).trim(),
      reading: readingOrNull,
    );
  }

  // Media-only front → derive expression + meaning from the back's lines.
  final List<String> lines = <String>[
    for (final String l in item.back.split('\n'))
      if (cleanSentence(l).trim().isNotEmpty) cleanSentence(l).trim(),
  ];
  return CardFields(
    expression: lines.isNotEmpty ? lines.first : '',
    meaning: lines.length > 1 ? lines.sublist(1).join(' ') : '',
    reading: readingOrNull,
  );
}

import '../import/source/imported_anki_source.dart';
import '../learning_item.dart';
import 'sentence_text.dart';

/// The raw material for a sentence-builder round, before tokenization
/// (MVP_016). The sentence still needs to be tokenized by the service.
class SentenceSource {
  const SentenceSource({
    required this.itemId,
    required this.sentence,
    this.noteId,
    this.translation,
    this.audioRef,
    this.reading,
  });

  final String itemId;
  final String sentence;
  final String? noteId;
  final String? translation;
  final String? audioRef;
  final String? reading;
}

/// Picks the best sentence (and its translation / audio / reading) for a card
/// from preserved Anki source fields, falling back to the mapped item. Pure and
/// synchronous — it does no tokenization and never touches review/FSRS state.
class SentenceBuilderMapper {
  const SentenceBuilderMapper();

  /// The sentence source for [item], or null when it has no usable sentence.
  SentenceSource? sourceFor(LearningItem item, {ImportedAnkiNote? note}) {
    final String? raw = _firstNonEmpty(<String?>[
      note?.fieldByName('Sentence')?.plainTextValue,
      note?.fieldByName('Sentence-Kana')?.plainTextValue,
      item.example,
    ]);
    if (raw == null) return null;

    final String sentence = cleanSentence(raw);
    if (!looksLikeSentence(sentence)) return null;

    return SentenceSource(
      itemId: item.id,
      sentence: sentence,
      noteId: note?.sourceNoteId ?? item.importedProgress?.sourceNoteId,
      translation:
          _cleanOrNull(note?.fieldByName('Sentence-English')?.plainTextValue),
      reading: _cleanOrNull(_firstNonEmpty(<String?>[
        note?.fieldByName('Sentence-Kana')?.plainTextValue,
        note?.fieldByName('Sentence-Furigana')?.plainTextValue,
        item.reading,
      ])),
      // The sentence audio is often embedded as [sound:…] in the same field the
      // sentence came from (a note Sentence field, or the item's example).
      audioRef: soundRefIn(<String?>[
            note?.fieldByName('Sentence')?.rawValue,
            note?.fieldByName('Sentence Audio')?.rawValue,
            item.example,
            note?.fieldByName('Sentence')?.plainTextValue,
          ]) ??
          _audioField(note),
    );
  }

  /// Whether [item] looks like it can produce a round (cheap, synchronous).
  bool looksCapable(LearningItem item, {ImportedAnkiNote? note}) =>
      sourceFor(item, note: note) != null;

  String? _audioField(ImportedAnkiNote? note) {
    final ImportedAnkiField? f = note?.fieldByName('Sentence Audio');
    if (f == null) return null;
    for (final MediaReference ref in f.mediaReferences) {
      if (ref.kind == MediaKind.audio) return ref.fileName;
    }
    return null;
  }

  String? _cleanOrNull(String? raw) {
    if (raw == null) return null;
    final String c = cleanSentence(raw);
    return c.isEmpty ? null : c;
  }

  String? _firstNonEmpty(List<String?> candidates) {
    for (final String? c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c;
    }
    return null;
  }
}

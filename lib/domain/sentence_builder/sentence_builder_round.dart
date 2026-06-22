import 'sentence_builder_source.dart';
import 'sentence_builder_token.dart';

/// A single sentence builder prompt and its correct token ordering.
class SentenceBuilderRound {
  const SentenceBuilderRound({
    required this.deckId,
    required this.source,
    required this.sentence,
    required this.tokens,
    this.itemId,
    this.noteId,
    this.translation,
    this.audioRef,
    this.reading,
  });

  final String deckId;
  final SentenceBuilderSource source;
  final String sentence;
  final List<SentenceBuilderToken> tokens;
  final String? itemId;
  final String? noteId;
  final String? translation;
  final String? audioRef;
  final String? reading;

  /// Correct token texts in sentence order.
  List<String> get correctOrder {
    return tokens.map((SentenceBuilderToken token) => token.text).toList();
  }

  /// Whether [attempt] matches the correct token text sequence.
  bool isCorrect(List<SentenceBuilderToken> attempt) {
    if (attempt.length != tokens.length) {
      return false;
    }

    for (int i = 0; i < attempt.length; i++) {
      if (attempt[i].text != tokens[i].text) {
        return false;
      }
    }

    return true;
  }
}

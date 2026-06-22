import 'cube_token.dart';

/// A tokenizer failure category.
enum TokenizerError {
  /// The tokenizer could not be reached.
  offline,

  /// The tokenizer rejected the configured credentials.
  unauthorized,

  /// The tokenizer rejected the request because of rate limits.
  rateLimited,

  /// The tokenizer rejected the input.
  invalidInput,

  /// The tokenizer failed or returned an invalid response.
  server,
}

/// Exception thrown when sentence tokenization fails.
class TokenizerException implements Exception {
  /// Creates a tokenizer exception.
  const TokenizerException(this.kind);

  /// The category of tokenizer failure.
  final TokenizerError kind;

  @override
  String toString() => 'TokenizerException($kind)';
}

/// Sentence tokenization result.
class TokenizeResult {
  /// Creates a tokenization result.
  const TokenizeResult({required this.lines, required this.tokens});

  /// Server-cleaned sentences.
  final List<String> lines;

  /// Word tokens for each line in [lines].
  final List<List<CubeToken>> tokens;
}

/// Tokenizes sentence lines into cube tokens.
abstract class SentenceTokenizer {
  /// Tokenizes [lines] and returns cleaned lines with their tokens.
  Future<TokenizeResult> tokenize(List<String> lines);
}

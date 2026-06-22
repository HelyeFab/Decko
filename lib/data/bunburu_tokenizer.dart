// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/sentence_builder/cube_token.dart';
import '../domain/sentence_builder/sentence_tokenizer.dart';

/// Sentence tokenizer backed by Bunburu's furigana endpoint.
class BunburuTokenizer implements SentenceTokenizer {
  /// Creates a Bunburu tokenizer client.
  BunburuTokenizer({
    required Uri baseUrl,
    required String appKey,
    http.Client? client,
  }) : _baseUrl = baseUrl,
       _appKey = appKey,
       _client = client ?? http.Client();

  final Uri _baseUrl;
  final String _appKey;
  final http.Client _client;

  @override
  Future<TokenizeResult> tokenize(List<String> lines) async {
    final http.Response response;
    try {
      response = await _client.post(
        _furiganaUri,
        headers: <String, String>{
          'x-app-key': _appKey,
          'content-type': 'application/json',
        },
        body: jsonEncode(<String, List<String>>{'lines': lines}),
      );
    } on SocketException {
      throw const TokenizerException(TokenizerError.offline);
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 400:
        throw const TokenizerException(TokenizerError.invalidInput);
      case 401:
      case 403:
        throw const TokenizerException(TokenizerError.unauthorized);
      case 429:
        throw const TokenizerException(TokenizerError.rateLimited);
      default:
        throw const TokenizerException(TokenizerError.server);
    }

    try {
      final Map<String, dynamic> json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<List<CubeToken>> tokens = (json['tokens'] as List<dynamic>)
          .map(
            (dynamic line) => (line as List<dynamic>)
                .map(
                  (dynamic token) =>
                      CubeToken.fromJson(token as Map<String, dynamic>),
                )
                .toList(growable: false),
          )
          .toList(growable: false);
      final List<String> cleanedLines =
          (json['lines'] as List<dynamic>?)?.cast<String>() ?? lines;

      return TokenizeResult(lines: cleanedLines, tokens: tokens);
    } on Object {
      throw const TokenizerException(TokenizerError.server);
    }
  }

  Uri get _furiganaUri {
    final String base = _baseUrl.toString().replaceFirst(RegExp(r'/*$'), '');
    return Uri.parse('$base/furigana');
  }
}

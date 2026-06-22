/// A text span with an optional furigana reading.
class FuriganaSegment {
  /// Creates a furigana segment.
  const FuriganaSegment({required this.text, this.ruby});

  /// The visible text for this segment.
  final String text;

  /// The reading shown above [text], when available.
  final String? ruby;

  /// Creates a segment from a JSON object.
  factory FuriganaSegment.fromJson(Map<String, dynamic> json) {
    return FuriganaSegment(
      text: json['text'] as String,
      ruby: json['ruby'] as String?,
    );
  }

  /// Converts this segment to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'text': text, if (ruby != null) 'ruby': ruby};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FuriganaSegment &&
            runtimeType == other.runtimeType &&
            text == other.text &&
            ruby == other.ruby;
  }

  @override
  int get hashCode => Object.hash(text, ruby);
}

/// A token returned by the sentence tokenizer.
class CubeToken {
  /// Creates a cube token.
  const CubeToken({
    required this.surface,
    this.furigana = const <FuriganaSegment>[],
    this.lookup,
  });

  /// The surface form shown in the sentence.
  final String surface;

  /// Furigana segments for rendering readings.
  final List<FuriganaSegment> furigana;

  /// Optional lookup form used for dictionary search.
  final String? lookup;

  /// Creates a cube token from a JSON object.
  factory CubeToken.fromJson(Map<String, dynamic> json) {
    final List<dynamic> furiganaJson =
        json['furigana'] as List<dynamic>? ?? <dynamic>[];

    return CubeToken(
      surface: json['surface'] as String,
      furigana: furiganaJson
          .map(
            (dynamic segment) =>
                FuriganaSegment.fromJson(segment as Map<String, dynamic>),
          )
          .toList(growable: false),
      lookup: json['lookup'] as String?,
    );
  }

  /// Converts this token to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'furigana': furigana
          .map((FuriganaSegment segment) => segment.toJson())
          .toList(growable: false),
      if (lookup != null) 'lookup': lookup,
    };
  }
}

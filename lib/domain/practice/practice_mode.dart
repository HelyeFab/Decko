/// Stable identifiers for Decko practice modes.
enum PracticeModeId {
  /// Bunburu sentence builder practice.
  bunburuSentenceBuilder,

  /// Listening challenge (audio → meaning) practice.
  listeningChallenge,

  /// Typing recall (prompt → type the reading/meaning) practice.
  typingRecall,
}

/// Storage helpers for [PracticeModeId].
extension PracticeModeIdName on PracticeModeId {
  /// Stable storage key for this practice mode.
  String get storageKey => switch (this) {
    PracticeModeId.bunburuSentenceBuilder => 'bunburu_sentence_builder',
    PracticeModeId.listeningChallenge => 'listening_challenge',
    PracticeModeId.typingRecall => 'typing_recall',
  };
}

/// Parses a practice mode id from its stable storage key.
PracticeModeId? practiceModeIdFromKey(String key) => switch (key) {
  'bunburu_sentence_builder' => PracticeModeId.bunburuSentenceBuilder,
  'listening_challenge' => PracticeModeId.listeningChallenge,
  'typing_recall' => PracticeModeId.typingRecall,
  _ => null,
};

/// The high-level category of practice.
enum PracticeModeKind {
  /// Build an answer from selectable parts.
  build,

  /// Listen and respond to audio.
  listen,

  /// Type an answer directly.
  type,

  /// Match related items.
  match,

  /// Recall an answer from memory.
  recall,

  /// Answer a quiz prompt.
  quiz,
}

/// Framework-light metadata describing a Decko practice mode.
class PracticeMode {
  /// Creates immutable practice mode metadata.
  const PracticeMode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.kind,
    required this.manualLaunch,
    required this.reviewPresentation,
  });

  /// Stable identifier for this practice mode.
  final PracticeModeId id;

  /// Short display title.
  final String title;

  /// One-line supporting display text.
  final String subtitle;

  /// Longer display description.
  final String description;

  /// The high-level practice category.
  final PracticeModeKind kind;

  /// Whether this mode can be launched manually from a card or deck.
  final bool manualLaunch;

  /// Whether this mode can be routed by the scheduler as a review presentation.
  final bool reviewPresentation;

  /// Whether this mode has the same stable id as [other].
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PracticeMode && id == other.id;

  /// Hashes this mode by stable id.
  @override
  int get hashCode => id.hashCode;

  /// Returns a concise debug representation.
  @override
  String toString() => 'PracticeMode(id: ${id.storageKey}, title: $title)';
}

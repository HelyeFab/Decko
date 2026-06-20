/// What an imported Anki card is trying to train (MVP_010).
///
/// Derived from the preserved Anki source — card-template identity first, then
/// named fields — so a note that generates Listening / Reading / Production
/// cards is presented as three *different* study activities, not three
/// lookalikes. [generic] is the fallback for simple/positional decks.
enum ReviewCardMode { generic, listening, reading, production }

extension ReviewCardModeLabel on ReviewCardMode {
  /// The quiet eyebrow shown on the card, or null for [generic] (no label).
  String? get label => switch (this) {
        ReviewCardMode.listening => 'LISTENING',
        ReviewCardMode.reading => 'READING',
        ReviewCardMode.production => 'PRODUCTION',
        ReviewCardMode.generic => null,
      };

  String get name => switch (this) {
        ReviewCardMode.listening => 'listening',
        ReviewCardMode.reading => 'reading',
        ReviewCardMode.production => 'production',
        ReviewCardMode.generic => 'generic',
      };
}

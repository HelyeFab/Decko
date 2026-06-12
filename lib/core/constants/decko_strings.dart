/// User-facing copy, kept central and in British English.
abstract final class DeckoStrings {
  static const String wordmark = 'Decko';
  static const String tagline = 'Import your deck. Study it beautifully.';

  // Home / deck library.
  static const String emptyTitle = 'No decks yet';
  static const String emptyBody =
      'Bring in your own cards or take Decko for a spin with our demo deck.';
  static const String importCta = 'Import a deck';
  static const String demoCta = 'Explore demo deck';

  // The product promise, shown as small feature chips.
  static const List<(String, String)> promises = <(String, String)>[
    ('FSRS-ready reviews', 'Modern spaced repetition'),
    ('Beautiful card themes', 'Cards you enjoy looking at'),
    ('XP and streaks', 'Stay motivated daily'),
    ('Multiple study modes', 'More than just flip cards'),
  ];
}

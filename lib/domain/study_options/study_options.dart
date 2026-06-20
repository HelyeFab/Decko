// Study options: global defaults, per-deck overrides, and the effective values
// a review session actually consumes (MVP_011, DEC-020).
//
// Framework-light: no Flutter imports. FSRS maths stays in the scheduler layer;
// these options only shape which cards enter a session and how media / readings
// are presented.

/// When prompt/answer audio plays on its own.
enum AudioAutoplayMode { off, beforeQuestion, afterReveal }

/// Whether a card's image shows with the question or only after the reveal.
enum ImageDisplayMode { withQuestion, afterReveal }

/// A deck's furigana choice, layered over the global furigana toggle.
enum FuriganaPreference { useGlobal, alwaysShow, alwaysHide }

/// Global study defaults that apply to every deck unless a deck overrides them.
class StudyOptions {
  const StudyOptions({
    this.newCardsPerDay = 20,
    this.reviewCardsPerDay = 200,
    this.maxSessionCards = 100,
    this.audioAutoplayMode = AudioAutoplayMode.off,
    this.imageDisplayMode = ImageDisplayMode.withQuestion,
    this.burySiblingsUntilTomorrow = false,
  });

  final int newCardsPerDay;
  final int reviewCardsPerDay;
  final int maxSessionCards;
  final AudioAutoplayMode audioAutoplayMode;
  final ImageDisplayMode imageDisplayMode;
  final bool burySiblingsUntilTomorrow;

  static const StudyOptions defaults = StudyOptions();

  StudyOptions copyWith({
    int? newCardsPerDay,
    int? reviewCardsPerDay,
    int? maxSessionCards,
    AudioAutoplayMode? audioAutoplayMode,
    ImageDisplayMode? imageDisplayMode,
    bool? burySiblingsUntilTomorrow,
  }) {
    return StudyOptions(
      newCardsPerDay: newCardsPerDay ?? this.newCardsPerDay,
      reviewCardsPerDay: reviewCardsPerDay ?? this.reviewCardsPerDay,
      maxSessionCards: maxSessionCards ?? this.maxSessionCards,
      audioAutoplayMode: audioAutoplayMode ?? this.audioAutoplayMode,
      imageDisplayMode: imageDisplayMode ?? this.imageDisplayMode,
      burySiblingsUntilTomorrow:
          burySiblingsUntilTomorrow ?? this.burySiblingsUntilTomorrow,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'newCardsPerDay': newCardsPerDay,
        'reviewCardsPerDay': reviewCardsPerDay,
        'maxSessionCards': maxSessionCards,
        'audioAutoplayMode': audioAutoplayMode.name,
        'imageDisplayMode': imageDisplayMode.name,
        'burySiblingsUntilTomorrow': burySiblingsUntilTomorrow,
      };

  static StudyOptions fromMap(Map<String, dynamic> m) => StudyOptions(
        newCardsPerDay: m['newCardsPerDay'] as int? ?? 20,
        reviewCardsPerDay: m['reviewCardsPerDay'] as int? ?? 200,
        maxSessionCards: m['maxSessionCards'] as int? ?? 100,
        audioAutoplayMode: _enumByName(
            AudioAutoplayMode.values, m['audioAutoplayMode'], AudioAutoplayMode.off),
        imageDisplayMode: _enumByName(ImageDisplayMode.values,
            m['imageDisplayMode'], ImageDisplayMode.withQuestion),
        burySiblingsUntilTomorrow:
            m['burySiblingsUntilTomorrow'] as bool? ?? false,
      );
}

/// Per-deck overrides. Every value is nullable — null means "use the global
/// default". Furigana is deck-only (layered over the global toggle).
class DeckStudyOptions {
  const DeckStudyOptions({
    this.newCardsPerDay,
    this.reviewCardsPerDay,
    this.maxSessionCards,
    this.audioAutoplayMode,
    this.imageDisplayMode,
    this.burySiblingsUntilTomorrow,
    this.furiganaPreference = FuriganaPreference.useGlobal,
  });

  final int? newCardsPerDay;
  final int? reviewCardsPerDay;
  final int? maxSessionCards;
  final AudioAutoplayMode? audioAutoplayMode;
  final ImageDisplayMode? imageDisplayMode;
  final bool? burySiblingsUntilTomorrow;
  final FuriganaPreference furiganaPreference;

  static const DeckStudyOptions none = DeckStudyOptions();

  DeckStudyOptions copyWith({
    Object? newCardsPerDay = _unset,
    Object? reviewCardsPerDay = _unset,
    Object? maxSessionCards = _unset,
    Object? audioAutoplayMode = _unset,
    Object? imageDisplayMode = _unset,
    Object? burySiblingsUntilTomorrow = _unset,
    FuriganaPreference? furiganaPreference,
  }) {
    return DeckStudyOptions(
      newCardsPerDay: newCardsPerDay == _unset
          ? this.newCardsPerDay
          : newCardsPerDay as int?,
      reviewCardsPerDay: reviewCardsPerDay == _unset
          ? this.reviewCardsPerDay
          : reviewCardsPerDay as int?,
      maxSessionCards: maxSessionCards == _unset
          ? this.maxSessionCards
          : maxSessionCards as int?,
      audioAutoplayMode: audioAutoplayMode == _unset
          ? this.audioAutoplayMode
          : audioAutoplayMode as AudioAutoplayMode?,
      imageDisplayMode: imageDisplayMode == _unset
          ? this.imageDisplayMode
          : imageDisplayMode as ImageDisplayMode?,
      burySiblingsUntilTomorrow: burySiblingsUntilTomorrow == _unset
          ? this.burySiblingsUntilTomorrow
          : burySiblingsUntilTomorrow as bool?,
      furiganaPreference: furiganaPreference ?? this.furiganaPreference,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (newCardsPerDay != null) 'newCardsPerDay': newCardsPerDay,
        if (reviewCardsPerDay != null) 'reviewCardsPerDay': reviewCardsPerDay,
        if (maxSessionCards != null) 'maxSessionCards': maxSessionCards,
        if (audioAutoplayMode != null)
          'audioAutoplayMode': audioAutoplayMode!.name,
        if (imageDisplayMode != null) 'imageDisplayMode': imageDisplayMode!.name,
        if (burySiblingsUntilTomorrow != null)
          'burySiblingsUntilTomorrow': burySiblingsUntilTomorrow,
        'furiganaPreference': furiganaPreference.name,
      };

  static DeckStudyOptions fromMap(Map<String, dynamic> m) => DeckStudyOptions(
        newCardsPerDay: m['newCardsPerDay'] as int?,
        reviewCardsPerDay: m['reviewCardsPerDay'] as int?,
        maxSessionCards: m['maxSessionCards'] as int?,
        audioAutoplayMode: m['audioAutoplayMode'] == null
            ? null
            : _enumByName(AudioAutoplayMode.values, m['audioAutoplayMode'],
                AudioAutoplayMode.off),
        imageDisplayMode: m['imageDisplayMode'] == null
            ? null
            : _enumByName(ImageDisplayMode.values, m['imageDisplayMode'],
                ImageDisplayMode.withQuestion),
        burySiblingsUntilTomorrow: m['burySiblingsUntilTomorrow'] as bool?,
        furiganaPreference: _enumByName(FuriganaPreference.values,
            m['furiganaPreference'], FuriganaPreference.useGlobal),
      );
}

/// The resolved options a session uses: deck override else global default.
class EffectiveStudyOptions {
  const EffectiveStudyOptions({
    required this.newCardsPerDay,
    required this.reviewCardsPerDay,
    required this.maxSessionCards,
    required this.audioAutoplayMode,
    required this.imageDisplayMode,
    required this.burySiblingsUntilTomorrow,
    required this.furiganaPreference,
  });

  final int newCardsPerDay;
  final int reviewCardsPerDay;
  final int maxSessionCards;
  final AudioAutoplayMode audioAutoplayMode;
  final ImageDisplayMode imageDisplayMode;
  final bool burySiblingsUntilTomorrow;
  final FuriganaPreference furiganaPreference;

  /// Deck override wins where set; otherwise the global default is used.
  factory EffectiveStudyOptions.resolve(
    StudyOptions global,
    DeckStudyOptions? deck,
  ) {
    return EffectiveStudyOptions(
      newCardsPerDay: deck?.newCardsPerDay ?? global.newCardsPerDay,
      reviewCardsPerDay: deck?.reviewCardsPerDay ?? global.reviewCardsPerDay,
      maxSessionCards: deck?.maxSessionCards ?? global.maxSessionCards,
      audioAutoplayMode: deck?.audioAutoplayMode ?? global.audioAutoplayMode,
      imageDisplayMode: deck?.imageDisplayMode ?? global.imageDisplayMode,
      burySiblingsUntilTomorrow:
          deck?.burySiblingsUntilTomorrow ?? global.burySiblingsUntilTomorrow,
      furiganaPreference:
          deck?.furiganaPreference ?? FuriganaPreference.useGlobal,
    );
  }

  /// Whether to show furigana, given the global toggle, after applying the
  /// deck-level preference.
  bool resolveShowFurigana(bool globalOn) => switch (furiganaPreference) {
        FuriganaPreference.alwaysShow => true,
        FuriganaPreference.alwaysHide => false,
        FuriganaPreference.useGlobal => globalOn,
      };
}

const Object _unset = Object();

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

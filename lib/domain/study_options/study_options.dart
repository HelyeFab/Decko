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

/// The order new cards are introduced in a session.
enum NewCardOrder { deckOrder, random }

/// Global study defaults that apply to every deck unless a deck overrides them.
class StudyOptions {
  const StudyOptions({
    this.newCardsPerDay = 20,
    this.reviewCardsPerDay = 200,
    this.maxSessionCards = 100,
    this.audioAutoplayMode = AudioAutoplayMode.off,
    this.imageDisplayMode = ImageDisplayMode.withQuestion,
    this.burySiblingsUntilTomorrow = false,
    this.newCardOrder = NewCardOrder.deckOrder,
    this.sentenceBuilderReview = false,
  });

  final int newCardsPerDay;
  final int reviewCardsPerDay;
  final int maxSessionCards;
  final AudioAutoplayMode audioAutoplayMode;
  final ImageDisplayMode imageDisplayMode;
  final bool burySiblingsUntilTomorrow;
  final NewCardOrder newCardOrder;

  /// When on, due cards that have a usable sentence are reviewed as a
  /// sentence-builder challenge. Grading still flows through the normal
  /// review-answer seam — this only changes presentation (MVP_016, DEC-025).
  final bool sentenceBuilderReview;

  static const StudyOptions defaults = StudyOptions();

  StudyOptions copyWith({
    int? newCardsPerDay,
    int? reviewCardsPerDay,
    int? maxSessionCards,
    AudioAutoplayMode? audioAutoplayMode,
    ImageDisplayMode? imageDisplayMode,
    bool? burySiblingsUntilTomorrow,
    NewCardOrder? newCardOrder,
    bool? sentenceBuilderReview,
  }) {
    return StudyOptions(
      newCardsPerDay: newCardsPerDay ?? this.newCardsPerDay,
      reviewCardsPerDay: reviewCardsPerDay ?? this.reviewCardsPerDay,
      maxSessionCards: maxSessionCards ?? this.maxSessionCards,
      audioAutoplayMode: audioAutoplayMode ?? this.audioAutoplayMode,
      imageDisplayMode: imageDisplayMode ?? this.imageDisplayMode,
      burySiblingsUntilTomorrow:
          burySiblingsUntilTomorrow ?? this.burySiblingsUntilTomorrow,
      newCardOrder: newCardOrder ?? this.newCardOrder,
      sentenceBuilderReview:
          sentenceBuilderReview ?? this.sentenceBuilderReview,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'newCardsPerDay': newCardsPerDay,
        'reviewCardsPerDay': reviewCardsPerDay,
        'maxSessionCards': maxSessionCards,
        'audioAutoplayMode': audioAutoplayMode.name,
        'imageDisplayMode': imageDisplayMode.name,
        'burySiblingsUntilTomorrow': burySiblingsUntilTomorrow,
        'newCardOrder': newCardOrder.name,
        'sentenceBuilderReview': sentenceBuilderReview,
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
        newCardOrder: _enumByName(
            NewCardOrder.values, m['newCardOrder'], NewCardOrder.deckOrder),
        sentenceBuilderReview: m['sentenceBuilderReview'] as bool? ?? false,
      );
}

/// A reusable, named set of study options assignable to many decks (MVP_012).
/// The synthetic "default" profile mirrors the global defaults.
class StudyOptionProfile {
  const StudyOptionProfile({
    required this.id,
    required this.name,
    required this.options,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final StudyOptions options;
  final bool isDefault;

  /// The id of the built-in default profile (mirrors the global defaults).
  static const String defaultId = 'default';

  StudyOptionProfile copyWith({String? name, StudyOptions? options}) =>
      StudyOptionProfile(
        id: id,
        name: name ?? this.name,
        options: options ?? this.options,
        isDefault: isDefault,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'options': options.toMap(),
        'isDefault': isDefault,
      };

  static StudyOptionProfile fromMap(Map<String, dynamic> m) =>
      StudyOptionProfile(
        id: m['id'] as String,
        name: m['name'] as String? ?? 'Profile',
        options:
            StudyOptions.fromMap((m['options'] as Map).cast<String, dynamic>()),
        isDefault: m['isDefault'] as bool? ?? false,
      );
}

/// Per-deck overrides. Every value is nullable — null means "use the global
/// default". Furigana is deck-only (layered over the global toggle).
class DeckStudyOptions {
  const DeckStudyOptions({
    this.profileId,
    this.newCardsPerDay,
    this.reviewCardsPerDay,
    this.maxSessionCards,
    this.audioAutoplayMode,
    this.imageDisplayMode,
    this.burySiblingsUntilTomorrow,
    this.newCardOrder,
    this.furiganaPreference = FuriganaPreference.useGlobal,
  });

  /// The assigned profile, or null = the default/global options (MVP_012).
  final String? profileId;
  final int? newCardsPerDay;
  final int? reviewCardsPerDay;
  final int? maxSessionCards;
  final AudioAutoplayMode? audioAutoplayMode;
  final ImageDisplayMode? imageDisplayMode;
  final bool? burySiblingsUntilTomorrow;
  final NewCardOrder? newCardOrder;
  final FuriganaPreference furiganaPreference;

  static const DeckStudyOptions none = DeckStudyOptions();

  DeckStudyOptions copyWith({
    Object? profileId = _unset,
    Object? newCardsPerDay = _unset,
    Object? reviewCardsPerDay = _unset,
    Object? maxSessionCards = _unset,
    Object? audioAutoplayMode = _unset,
    Object? imageDisplayMode = _unset,
    Object? burySiblingsUntilTomorrow = _unset,
    Object? newCardOrder = _unset,
    FuriganaPreference? furiganaPreference,
  }) {
    return DeckStudyOptions(
      profileId: profileId == _unset ? this.profileId : profileId as String?,
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
      newCardOrder: newCardOrder == _unset
          ? this.newCardOrder
          : newCardOrder as NewCardOrder?,
      furiganaPreference: furiganaPreference ?? this.furiganaPreference,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (profileId != null) 'profileId': profileId,
        if (newCardsPerDay != null) 'newCardsPerDay': newCardsPerDay,
        if (reviewCardsPerDay != null) 'reviewCardsPerDay': reviewCardsPerDay,
        if (maxSessionCards != null) 'maxSessionCards': maxSessionCards,
        if (audioAutoplayMode != null)
          'audioAutoplayMode': audioAutoplayMode!.name,
        if (imageDisplayMode != null) 'imageDisplayMode': imageDisplayMode!.name,
        if (burySiblingsUntilTomorrow != null)
          'burySiblingsUntilTomorrow': burySiblingsUntilTomorrow,
        if (newCardOrder != null) 'newCardOrder': newCardOrder!.name,
        'furiganaPreference': furiganaPreference.name,
      };

  static DeckStudyOptions fromMap(Map<String, dynamic> m) => DeckStudyOptions(
        profileId: m['profileId'] as String?,
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
        newCardOrder: m['newCardOrder'] == null
            ? null
            : _enumByName(NewCardOrder.values, m['newCardOrder'],
                NewCardOrder.deckOrder),
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
    required this.newCardOrder,
    required this.furiganaPreference,
    required this.sentenceBuilderReview,
  });

  final int newCardsPerDay;
  final int reviewCardsPerDay;
  final int maxSessionCards;
  final AudioAutoplayMode audioAutoplayMode;
  final ImageDisplayMode imageDisplayMode;
  final bool burySiblingsUntilTomorrow;
  final NewCardOrder newCardOrder;
  final FuriganaPreference furiganaPreference;
  final bool sentenceBuilderReview;

  /// Resolves global/default → (profile) → deck override. [base] is the global
  /// defaults or, when a profile is assigned, the profile's options (MVP_012).
  /// Deck override wins per-field; unset fields fall back to [base].
  factory EffectiveStudyOptions.resolve(
    StudyOptions base,
    DeckStudyOptions? deck,
  ) {
    return EffectiveStudyOptions(
      newCardsPerDay: deck?.newCardsPerDay ?? base.newCardsPerDay,
      reviewCardsPerDay: deck?.reviewCardsPerDay ?? base.reviewCardsPerDay,
      maxSessionCards: deck?.maxSessionCards ?? base.maxSessionCards,
      audioAutoplayMode: deck?.audioAutoplayMode ?? base.audioAutoplayMode,
      imageDisplayMode: deck?.imageDisplayMode ?? base.imageDisplayMode,
      burySiblingsUntilTomorrow:
          deck?.burySiblingsUntilTomorrow ?? base.burySiblingsUntilTomorrow,
      newCardOrder: deck?.newCardOrder ?? base.newCardOrder,
      furiganaPreference:
          deck?.furiganaPreference ?? FuriganaPreference.useGlobal,
      // Global-only for now: the review presentation toggle isn't per-deck.
      sentenceBuilderReview: base.sentenceBuilderReview,
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

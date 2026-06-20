import '../review_card_mode.dart';
import 'source/imported_anki_source.dart';

/// The result of mapping one preserved Anki card to a Decko presentation.
///
/// Carries both the Decko-facing content (front/back/reading/example + [mode])
/// and an inspectable rationale ([matchedBy], [frontFields], [backFields]) so
/// import behaviour is explainable when a card lands in the "wrong" mode.
class CardMapping {
  const CardMapping({
    required this.mode,
    required this.recognized,
    required this.front,
    required this.back,
    this.reading,
    this.example,
    required this.matchedBy,
    this.frontFields = const <String>[],
    this.backFields = const <String>[],
  });

  final ReviewCardMode mode;

  /// False when the source wasn't rich enough to improve on the positional
  /// mapping — the caller should keep its existing (fallback) content.
  final bool recognized;

  final String front;
  final String back;
  final String? reading;
  final String? example;

  /// Human-readable reason the [mode] was chosen (e.g. template name match).
  final String matchedBy;

  /// Source field names feeding the front / back, for the inspect view.
  final List<String> frontFields;
  final List<String> backFields;
}

/// Turns preserved Anki source cards into note-type-aware Decko presentations
/// (MVP_010, DEC-019).
///
/// Template identity is preferred (Listening / Reading / Production …); named
/// fields resolve the rest (expression, reading, meaning, sentence, audio,
/// image). When neither offers a useful signal the mapping is reported
/// [CardMapping.recognized] = false so the caller falls back to its positional
/// mapping — simple/demo decks are untouched. Pure and framework-light.
class NoteTypeAwareCardMapper {
  const NoteTypeAwareCardMapper();

  CardMapping map({
    required ImportedAnkiSource source,
    required ImportedAnkiCardSource cardSource,
  }) {
    final ImportedAnkiNote? note = source.noteById(cardSource.sourceNoteId);
    if (note == null) {
      return const CardMapping(
        mode: ReviewCardMode.generic,
        recognized: false,
        front: '',
        back: '',
        matchedBy: 'no source note',
      );
    }

    final _Roles roles = _Roles.resolve(note.fields);
    final String? templateName =
        cardSource.templateName ?? _templateName(source, note, cardSource);
    final (ReviewCardMode mode, String why) = _modeFor(templateName, roles);

    // Recognised when we have a real template signal or enough named-field
    // roles to do better than positional guessing. Plain Front/Back/Field decks
    // resolve to no roles → fall back so existing mapping/tests are untouched.
    final bool recognized = mode != ReviewCardMode.generic || roles.isRich;
    if (!recognized) {
      return CardMapping(
        mode: ReviewCardMode.generic,
        recognized: false,
        front: '',
        back: '',
        matchedBy: why,
      );
    }
    return _compose(mode: mode, why: why, roles: roles);
  }

  String? _templateName(ImportedAnkiSource source, ImportedAnkiNote note,
      ImportedAnkiCardSource cardSource) {
    return source
        .modelById(note.sourceModelId)
        ?.templateByOrdinal(cardSource.templateOrdinal)
        ?.name;
  }

  (ReviewCardMode, String) _modeFor(String? templateName, _Roles roles) {
    final String t = _norm(templateName ?? '');
    if (t.isNotEmpty) {
      if (t.contains('listening') || t.contains('listen')) {
        return (ReviewCardMode.listening, 'template name “$templateName”');
      }
      if (t.contains('production') ||
          t.contains('produce') ||
          t.contains('recall') ||
          t.contains('writing')) {
        return (ReviewCardMode.production, 'template name “$templateName”');
      }
      if (t.contains('reading') ||
          t.contains('read') ||
          t.contains('recognition') ||
          t.contains('recognise') ||
          t.contains('recognize')) {
        return (ReviewCardMode.reading, 'template name “$templateName”');
      }
    }
    return (ReviewCardMode.generic, 'no template-mode signal; mapped by fields');
  }

  CardMapping _compose({
    required ReviewCardMode mode,
    required String why,
    required _Roles roles,
  }) {
    final String jpWord = roles.text(_Role.expression);
    final String wordAudio = roles.media(_Role.wordAudio, _Role.expression);
    final String image = roles.media(_Role.image);
    final String meaning = roles.text(_Role.meaning);
    final String? kana = roles.optionalText(_Role.reading);
    final String? example = _example(roles);

    final List<String> front = <String>[];
    final List<String> back = <String>[];

    switch (mode) {
      case ReviewCardMode.listening:
        // Hear it first; the word is revealed on the back.
        final String f = <String>[wordAudio, image]
            .where((String s) => s.isNotEmpty)
            .join(' ');
        return CardMapping(
          mode: mode,
          recognized: true,
          front: f.isEmpty ? jpWord : f, // no audio → fall back to the word
          back: <String>[jpWord, meaning]
              .where((String s) => s.isNotEmpty)
              .join('\n'),
          reading: null,
          example: example,
          matchedBy: why,
          frontFields: roles.names(<_Role>[_Role.wordAudio, _Role.image]),
          backFields: roles.names(<_Role>[
            _Role.expression,
            _Role.reading,
            _Role.meaning,
            _Role.sentence,
          ]),
        );
      case ReviewCardMode.production:
        // Prompt in English; the Japanese answer stays hidden until flip.
        front.add(meaning);
        final String? enHint = roles.optionalText(_Role.sentenceEnglish);
        if (enHint != null) front.add(enHint);
        return CardMapping(
          mode: mode,
          recognized: true,
          front: front.where((String s) => s.isNotEmpty).join('\n'),
          back: <String>[jpWord, wordAudio, image]
              .where((String s) => s.isNotEmpty)
              .join(' '),
          reading: kana,
          example: example,
          matchedBy: why,
          frontFields:
              roles.names(<_Role>[_Role.meaning, _Role.sentenceEnglish]),
          backFields: roles.names(<_Role>[
            _Role.expression,
            _Role.wordAudio,
            _Role.image,
            _Role.sentence,
          ]),
        );
      case ReviewCardMode.reading:
      case ReviewCardMode.generic:
        // See the Japanese; recall reading + meaning.
        front.add(<String>[jpWord, wordAudio, image]
            .where((String s) => s.isNotEmpty)
            .join(' '));
        back.add(meaning);
        return CardMapping(
          mode: mode,
          recognized: true,
          front: front.where((String s) => s.isNotEmpty).join(' '),
          back: meaning,
          reading: kana,
          example: example,
          matchedBy: why,
          frontFields: roles
              .names(<_Role>[_Role.expression, _Role.wordAudio, _Role.image]),
          backFields: roles.names(<_Role>[
            _Role.reading,
            _Role.meaning,
            _Role.sentence,
            _Role.sentenceEnglish,
          ]),
        );
    }
  }

  String? _example(_Roles roles) {
    final List<String> parts = <String>[
      roles.text(_Role.sentence),
      roles.text(_Role.sentenceEnglish),
      roles.media(_Role.sentenceAudio),
    ].where((String s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join('\n');
  }
}

// --- field-role resolution --------------------------------------------------

enum _Role {
  expression,
  reading,
  meaning,
  sentence,
  sentenceKana,
  sentenceEnglish,
  sentenceAudio,
  wordAudio,
  image,
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[\s_\-/]+'), '');

/// Resolves a note's named fields to semantic roles by name (first match wins),
/// most-specific patterns first. Generic names like `Front`/`Back`/`Field N`
/// deliberately match nothing, so plain decks fall through to positional.
class _Roles {
  _Roles(this._byRole);

  final Map<_Role, ImportedAnkiField> _byRole;

  static _Roles resolve(List<ImportedAnkiField> fields) {
    final Map<_Role, ImportedAnkiField> byRole = <_Role, ImportedAnkiField>{};
    for (final ImportedAnkiField f in fields) {
      final _Role? role = _roleOf(f.name);
      if (role != null) byRole.putIfAbsent(role, () => f);
    }
    // If there's no explicit expression but a reading field exists, the reading
    // field usually carries the word itself (with furigana) — use it as both.
    if (!byRole.containsKey(_Role.expression) &&
        byRole.containsKey(_Role.reading)) {
      byRole[_Role.expression] = byRole[_Role.reading]!;
      byRole.remove(_Role.reading); // avoid duplicating it as a separate line
    }
    return _Roles(byRole);
  }

  static _Role? _roleOf(String name) {
    final String n = _norm(name);
    if (n.isEmpty) return null;
    final bool sentence = n.contains('sentence') || n.contains('example');
    if (sentence && (n.contains('audio') || n.contains('sound'))) {
      return _Role.sentenceAudio;
    }
    if (sentence &&
        (n.contains('kana') ||
            n.contains('reading') ||
            n.contains('furigana'))) {
      return _Role.sentenceKana;
    }
    if (sentence &&
        (n.contains('english') ||
            n.contains('meaning') ||
            n.contains('translation') ||
            n.endsWith('eng'))) {
      return _Role.sentenceEnglish;
    }
    if (sentence) return _Role.sentence;
    if (n.contains('image') ||
        n.contains('picture') ||
        n.contains('photo') ||
        n == 'img') {
      return _Role.image;
    }
    if (n.contains('audio') || n.contains('sound') || n.contains('pronunci')) {
      return _Role.wordAudio;
    }
    if (n.contains('reading') ||
        n == 'kana' ||
        n.contains('furigana') ||
        n == 'yomi') {
      return _Role.reading;
    }
    if (n.contains('meaning') ||
        n.contains('english') ||
        n == 'gloss' ||
        n.contains('definition') ||
        n.contains('translation') ||
        n == 'eng' ||
        n == 'def') {
      return _Role.meaning;
    }
    if (n.contains('expression') ||
        n == 'word' ||
        n.contains('vocab') ||
        n == 'term' ||
        n.contains('kanji') ||
        n.contains('japanese') ||
        n == 'target' ||
        n.contains('headword')) {
      return _Role.expression;
    }
    return null;
  }

  /// "Rich" enough to map by fields rather than positionally: at least two
  /// distinct content roles beyond a lone expression.
  bool get isRich {
    final int meaningful = <_Role>[
      _Role.reading,
      _Role.meaning,
      _Role.sentence,
      _Role.sentenceEnglish,
      _Role.sentenceAudio,
      _Role.wordAudio,
      _Role.image,
    ].where(_byRole.containsKey).length;
    return meaningful >= 2;
  }

  String text(_Role role) => _byRole[role]?.plainTextValue.trim() ?? '';

  String? optionalText(_Role role) {
    final String v = text(role);
    return v.isEmpty ? null : v;
  }

  /// Media markers (`[sound:…]` / `<img src="…">`) reconstructed from the
  /// given roles' references, in order, deduped — for DeckoFieldContent.
  String media(_Role primary, [_Role? secondary]) {
    final List<String> out = <String>[];
    for (final _Role role in <_Role>[primary, ?secondary]) {
      final ImportedAnkiField? f = _byRole[role];
      if (f == null) continue;
      for (final MediaReference r in f.mediaReferences) {
        final String marker = r.kind == MediaKind.audio
            ? '[sound:${r.fileName}]'
            : '<img src="${r.fileName}">';
        if (!out.contains(marker)) out.add(marker);
      }
    }
    return out.join(' ');
  }

  List<String> names(List<_Role> roles) => <String>[
        for (final _Role role in roles) ?_byRole[role]?.name,
      ];
}

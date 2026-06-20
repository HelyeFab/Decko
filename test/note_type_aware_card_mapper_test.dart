// Pure tests for the note-type-aware card mapper (MVP_010): template identity
// and named fields produce distinct Listening / Reading / Production cards.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/domain/import/note_type_aware_card_mapper.dart';
import 'package:decko/domain/import/source/imported_anki_source.dart';
import 'package:decko/domain/review_card_mode.dart';

ImportedAnkiField _f(String name, int ord, String plain,
        {List<MediaReference> media = const <MediaReference>[]}) =>
    ImportedAnkiField(
      name: name,
      ordinal: ord,
      rawValue: plain,
      plainTextValue: plain,
      mediaReferences: media,
    );

/// A rich Japanese note (word + reading + meaning + example + audio + image)
/// generating one card per template name.
ImportedAnkiSource _source(List<String> templates) {
  final List<ImportedAnkiField> fields = <ImportedAnkiField>[
    _f('Expression', 0, '会社[かいしゃ]'),
    _f('Meaning', 1, 'company'),
    _f('Audio', 2, '', media: const <MediaReference>[
      MediaReference(fileName: 'word.mp3', kind: MediaKind.audio),
    ]),
    _f('Sentence', 3, '会社へ行く'),
    _f('Sentence Audio', 4, '', media: const <MediaReference>[
      MediaReference(fileName: 'sent.mp3', kind: MediaKind.audio),
    ]),
    _f('Image', 5, '', media: const <MediaReference>[
      MediaReference(fileName: 'office.jpg', kind: MediaKind.image),
    ]),
  ];
  return ImportedAnkiSource(
    deckId: 'd',
    models: <ImportedAnkiModel>[
      ImportedAnkiModel(
        id: 'm',
        name: 'JP',
        fieldNames: fields.map((ImportedAnkiField f) => f.name).toList(),
        templates: <ImportedAnkiCardTemplate>[
          for (int i = 0; i < templates.length; i++)
            ImportedAnkiCardTemplate(
                sourceModelId: 'm',
                ordinal: i,
                name: templates[i],
                questionTemplate: '',
                answerTemplate: ''),
        ],
      ),
    ],
    notes: <ImportedAnkiNote>[
      ImportedAnkiNote(
        sourceNoteId: '100',
        sourceGuid: 'g',
        sourceModelId: 'm',
        modelName: 'JP',
        deckId: 'd',
        fields: fields,
        tags: const <String>[],
      ),
    ],
    cardSources: <ImportedAnkiCardSource>[
      for (int i = 0; i < templates.length; i++)
        ImportedAnkiCardSource(
          sourceCardId: '20$i',
          sourceNoteId: '100',
          sourceDeckId: 'd',
          templateOrdinal: i,
          templateName: templates[i],
          queueState: 'newCard',
          due: 0,
          reps: 0,
          lapses: 0,
        ),
    ],
  );
}

void main() {
  const NoteTypeAwareCardMapper mapper = NoteTypeAwareCardMapper();
  final ImportedAnkiSource source =
      _source(<String>['Listening', 'Reading', 'Production']);
  CardMapping mapAt(int ord) =>
      mapper.map(source: source, cardSource: source.cardSources[ord]);

  test('Listening / Reading / Production map to distinct modes and fronts', () {
    final CardMapping l = mapAt(0);
    final CardMapping r = mapAt(1);
    final CardMapping p = mapAt(2);
    expect(l.mode, ReviewCardMode.listening);
    expect(r.mode, ReviewCardMode.reading);
    expect(p.mode, ReviewCardMode.production);
    expect(<String>{l.front, r.front, p.front}.length, 3); // all different
  });

  test('Listening front prioritises word audio, not the Japanese text', () {
    final CardMapping l = mapAt(0);
    expect(l.front, contains('[sound:word.mp3]'));
    expect(l.front, isNot(contains('会社')));
    expect(l.back, contains('会社')); // word revealed on the back
  });

  test('Reading front shows the Japanese expression', () {
    expect(mapAt(1).front, contains('会社'));
  });

  test('Production prompts in English and hides Japanese until flip', () {
    final CardMapping p = mapAt(2);
    expect(p.front, contains('company'));
    expect(p.front, isNot(contains('会社'))); // no Japanese on the front
    expect(p.back, contains('会社')); // revealed on the back
  });

  test('sentence audio is not confused with word audio', () {
    final CardMapping r = mapAt(1);
    expect(r.example, contains('[sound:sent.mp3]'));
    expect(r.front, contains('[sound:word.mp3]'));
    expect(r.example, isNot(contains('word.mp3')));
  });

  test('image stays with the right side (listening front, production back)', () {
    expect(mapAt(0).front, contains('office.jpg'));
    expect(mapAt(2).back, contains('office.jpg'));
  });

  test('records inspect rationale: matched-by + front/back field names', () {
    final CardMapping l = mapAt(0);
    expect(l.matchedBy, contains('Listening'));
    expect(l.frontFields, contains('Audio'));
    expect(l.backFields, contains('Expression'));
  });

  test('unknown template + plain Front/Back fields falls back to generic', () {
    final ImportedAnkiSource plain = ImportedAnkiSource(
      deckId: 'd',
      models: const <ImportedAnkiModel>[
        ImportedAnkiModel(
          id: 'b',
          name: 'Basic',
          fieldNames: <String>['Front', 'Back'],
          templates: <ImportedAnkiCardTemplate>[
            ImportedAnkiCardTemplate(
                sourceModelId: 'b',
                ordinal: 0,
                name: 'Card 1',
                questionTemplate: '',
                answerTemplate: ''),
          ],
        ),
      ],
      notes: <ImportedAnkiNote>[
        ImportedAnkiNote(
          sourceNoteId: '1',
          sourceGuid: 'g',
          sourceModelId: 'b',
          modelName: 'Basic',
          deckId: 'd',
          fields: <ImportedAnkiField>[_f('Front', 0, 'x'), _f('Back', 1, 'y')],
          tags: const <String>[],
        ),
      ],
      cardSources: const <ImportedAnkiCardSource>[
        ImportedAnkiCardSource(
          sourceCardId: '1',
          sourceNoteId: '1',
          sourceDeckId: 'd',
          templateOrdinal: 0,
          templateName: 'Card 1',
          queueState: 'newCard',
          due: 0,
          reps: 0,
          lapses: 0,
        ),
      ],
    );
    final CardMapping m =
        mapper.map(source: plain, cardSource: plain.cardSources.single);
    expect(m.recognized, isFalse);
    expect(m.mode, ReviewCardMode.generic);
  });
}

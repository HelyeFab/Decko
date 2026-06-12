import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/deck.dart';
import '../domain/import/deck_import_info.dart';
import '../domain/import/imported_card_progress.dart';
import '../domain/import/imported_card_state.dart';
import '../domain/learning_item.dart';

/// Persists imported decks as a single JSON blob in `shared_preferences`.
///
/// Intentionally small (DEC-010): fine for a handful of decks. Many/large decks
/// would later move to a file or database, but the [load]/[save] seam means the
/// rest of the app wouldn't change.
class ImportedDeckStorage {
  const ImportedDeckStorage();

  static const String _key = 'decko.importedDecks';

  Future<List<Deck>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return const <Deck>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic d) => _deckFromMap(d as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <Deck>[]; // ignore corrupt storage rather than crash
    }
  }

  Future<void> save(List<Deck> decks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw =
        jsonEncode(decks.map(_deckToMap).toList(growable: false));
    await prefs.setString(_key, raw);
  }

  // --- serialisation ---------------------------------------------------------

  Map<String, dynamic> _deckToMap(Deck d) => <String, dynamic>{
        'id': d.id,
        'name': d.name,
        'description': d.description,
        'importInfo': d.importInfo == null
            ? null
            : <String, dynamic>{
                'progressMode': d.importInfo!.progressMode.name,
                'importedAt': d.importInfo!.importedAt.toIso8601String(),
                'sourceName': d.importInfo!.sourceName,
              },
        'items': d.items.map(_itemToMap).toList(growable: false),
      };

  Map<String, dynamic> _itemToMap(LearningItem i) => <String, dynamic>{
        'id': i.id,
        'front': i.front,
        'back': i.back,
        'reading': i.reading,
        'example': i.example,
        'tags': i.tags,
        'importedProgress': i.importedProgress == null
            ? null
            : <String, dynamic>{
                'state': i.importedProgress!.state.name,
                'sourceCardId': i.importedProgress!.sourceCardId,
                'sourceNoteId': i.importedProgress!.sourceNoteId,
                'dueAt': i.importedProgress!.dueAt?.toIso8601String(),
                'intervalDays': i.importedProgress!.intervalDays,
                'reps': i.importedProgress!.reps,
                'lapses': i.importedProgress!.lapses,
                'easeFactor': i.importedProgress!.easeFactor,
                'lastReviewedAt':
                    i.importedProgress!.lastReviewedAt?.toIso8601String(),
              },
      };

  Deck _deckFromMap(Map<String, dynamic> m) {
    final Map<String, dynamic>? info = m['importInfo'] as Map<String, dynamic>?;
    return Deck(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String,
      importInfo: info == null
          ? null
          : DeckImportInfo(
              progressMode: ImportProgressMode.values
                  .byName(info['progressMode'] as String),
              importedAt: DateTime.parse(info['importedAt'] as String),
              sourceName: (info['sourceName'] as String?) ?? 'Anki',
            ),
      items: (m['items'] as List<dynamic>)
          .map((dynamic i) => _itemFromMap(i as Map<String, dynamic>))
          .toList(),
    );
  }

  LearningItem _itemFromMap(Map<String, dynamic> m) {
    final Map<String, dynamic>? p =
        m['importedProgress'] as Map<String, dynamic>?;
    return LearningItem(
      id: m['id'] as String,
      front: m['front'] as String,
      back: m['back'] as String,
      reading: m['reading'] as String?,
      example: m['example'] as String?,
      tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      importedProgress: p == null
          ? null
          : ImportedCardProgress(
              state: ImportedCardState.values.byName(p['state'] as String),
              sourceCardId: p['sourceCardId'] as String?,
              sourceNoteId: p['sourceNoteId'] as String?,
              dueAt: _date(p['dueAt']),
              intervalDays: p['intervalDays'] as int?,
              reps: p['reps'] as int?,
              lapses: p['lapses'] as int?,
              easeFactor: (p['easeFactor'] as num?)?.toDouble(),
              lastReviewedAt: _date(p['lastReviewedAt']),
            ),
    );
  }

  DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);
}

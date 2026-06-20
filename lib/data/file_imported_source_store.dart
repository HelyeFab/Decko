import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/import/source/imported_anki_source.dart';
import '../domain/repositories/imported_source_store.dart';

/// [ImportedSourceStore] backed by one JSON file per deck on local disk.
///
/// Files live under `<appSupport>/decko_source/<deckId>.json`. Kept off
/// `shared_preferences` because the lossless source can be several MB for a
/// large deck (DEC-016). [baseDir] is injectable for tests.
class FileImportedSourceStore implements ImportedSourceStore {
  // ignore: prefer_initializing_formals
  const FileImportedSourceStore({Directory? baseDir}) : _baseDir = baseDir;

  final Directory? _baseDir;

  static const String _root = 'decko_source';

  Future<File> _file(String deckId, {bool create = false}) async {
    final Directory base = _baseDir ?? await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/$_root');
    if (create) await dir.create(recursive: true);
    return File('${dir.path}/${_safe(deckId)}.json');
  }

  @override
  Future<void> saveSource(ImportedAnkiSource source) async {
    final File f = await _file(source.deckId, create: true);
    await f.writeAsString(jsonEncode(_sourceToMap(source)));
  }

  @override
  Future<ImportedAnkiSource?> getSourceForDeck(String deckId) async {
    final File f = await _file(deckId);
    if (!f.existsSync()) return null;
    try {
      return _sourceFromMap(
          jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteSourceForDeck(String deckId) async {
    final File f = await _file(deckId);
    if (f.existsSync()) await f.delete();
  }

  String _safe(String name) =>
      name.replaceAll(RegExp(r'[\\/]+'), '_').replaceAll('..', '_');

  // --- serialisation ---------------------------------------------------------

  Map<String, dynamic> _sourceToMap(ImportedAnkiSource s) => <String, dynamic>{
        'deckId': s.deckId,
        'models': s.models.map(_modelToMap).toList(),
        'notes': s.notes.map(_noteToMap).toList(),
        'cardSources': s.cardSources.map(_cardToMap).toList(),
      };

  Map<String, dynamic> _modelToMap(ImportedAnkiModel m) => <String, dynamic>{
        'id': m.id,
        'name': m.name,
        'fieldNames': m.fieldNames,
        'templates': m.templates
            .map((ImportedAnkiCardTemplate t) => <String, dynamic>{
                  'ordinal': t.ordinal,
                  'name': t.name,
                  'qfmt': t.questionTemplate,
                  'afmt': t.answerTemplate,
                })
            .toList(),
      };

  Map<String, dynamic> _noteToMap(ImportedAnkiNote n) => <String, dynamic>{
        'sourceNoteId': n.sourceNoteId,
        'sourceGuid': n.sourceGuid,
        'sourceModelId': n.sourceModelId,
        'modelName': n.modelName,
        'tags': n.tags,
        'fields': n.fields
            .map((ImportedAnkiField f) => <String, dynamic>{
                  'name': f.name,
                  'ordinal': f.ordinal,
                  'raw': f.rawValue,
                  'plain': f.plainTextValue,
                  'media': f.mediaReferences
                      .map((MediaReference r) => <String, dynamic>{
                            'file': r.fileName,
                            'kind': r.kind.name,
                          })
                      .toList(),
                })
            .toList(),
      };

  Map<String, dynamic> _cardToMap(ImportedAnkiCardSource c) => <String, dynamic>{
        'sourceCardId': c.sourceCardId,
        'sourceNoteId': c.sourceNoteId,
        'templateOrdinal': c.templateOrdinal,
        'templateName': c.templateName,
        'queueState': c.queueState,
        'due': c.due,
        'reps': c.reps,
        'lapses': c.lapses,
      };

  ImportedAnkiSource _sourceFromMap(Map<String, dynamic> m) {
    final String deckId = m['deckId'] as String;
    return ImportedAnkiSource(
      deckId: deckId,
      models: (m['models'] as List<dynamic>)
          .map((dynamic e) => _modelFromMap(e as Map<String, dynamic>))
          .toList(),
      notes: (m['notes'] as List<dynamic>)
          .map((dynamic e) => _noteFromMap(deckId, e as Map<String, dynamic>))
          .toList(),
      cardSources: (m['cardSources'] as List<dynamic>)
          .map((dynamic e) => _cardFromMap(deckId, e as Map<String, dynamic>))
          .toList(),
    );
  }

  ImportedAnkiModel _modelFromMap(Map<String, dynamic> m) => ImportedAnkiModel(
        id: m['id'] as String,
        name: m['name'] as String,
        fieldNames: (m['fieldNames'] as List<dynamic>).cast<String>(),
        templates: (m['templates'] as List<dynamic>)
            .map((dynamic e) => e as Map<String, dynamic>)
            .map((Map<String, dynamic> t) => ImportedAnkiCardTemplate(
                  sourceModelId: m['id'] as String,
                  ordinal: t['ordinal'] as int,
                  name: t['name'] as String,
                  questionTemplate: t['qfmt'] as String? ?? '',
                  answerTemplate: t['afmt'] as String? ?? '',
                ))
            .toList(),
      );

  ImportedAnkiNote _noteFromMap(String deckId, Map<String, dynamic> m) =>
      ImportedAnkiNote(
        sourceNoteId: m['sourceNoteId'] as String,
        sourceGuid: m['sourceGuid'] as String? ?? '',
        sourceModelId: m['sourceModelId'] as String,
        modelName: m['modelName'] as String,
        deckId: deckId,
        tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
        fields: (m['fields'] as List<dynamic>)
            .map((dynamic e) => e as Map<String, dynamic>)
            .map((Map<String, dynamic> f) => ImportedAnkiField(
                  name: f['name'] as String,
                  ordinal: f['ordinal'] as int,
                  rawValue: f['raw'] as String,
                  plainTextValue: f['plain'] as String,
                  mediaReferences: (f['media'] as List<dynamic>?)
                          ?.map((dynamic e) => e as Map<String, dynamic>)
                          .map((Map<String, dynamic> r) => MediaReference(
                                fileName: r['file'] as String,
                                kind: MediaKind.values.byName(r['kind'] as String),
                              ))
                          .toList() ??
                      const <MediaReference>[],
                ))
            .toList(),
      );

  ImportedAnkiCardSource _cardFromMap(String deckId, Map<String, dynamic> m) =>
      ImportedAnkiCardSource(
        sourceCardId: m['sourceCardId'] as String,
        sourceNoteId: m['sourceNoteId'] as String,
        sourceDeckId: deckId,
        templateOrdinal: m['templateOrdinal'] as int,
        templateName: m['templateName'] as String?,
        queueState: m['queueState'] as String,
        due: m['due'] as int? ?? 0,
        reps: m['reps'] as int? ?? 0,
        lapses: m['lapses'] as int? ?? 0,
      );
}

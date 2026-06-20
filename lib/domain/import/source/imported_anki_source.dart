/// Lossless representation of an imported Anki package's note data.
///
/// Decko renders a simplified study card, but the original Anki source — every
/// named field (raw + plain), tags, model/field/template definitions, and the
/// card→note→template links — is preserved here so future note-type-aware
/// mapping, deck options, and study modes can use it without re-importing
/// (DEC-016). Framework-light: no Flutter imports.
class ImportedAnkiSource {
  const ImportedAnkiSource({
    required this.deckId,
    required this.models,
    required this.notes,
    required this.cardSources,
  });

  final String deckId;
  final List<ImportedAnkiModel> models;
  final List<ImportedAnkiNote> notes;
  final List<ImportedAnkiCardSource> cardSources;

  ImportedAnkiModel? modelById(String id) {
    for (final ImportedAnkiModel m in models) {
      if (m.id == id) return m;
    }
    return null;
  }

  ImportedAnkiNote? noteById(String id) {
    for (final ImportedAnkiNote n in notes) {
      if (n.sourceNoteId == id) return n;
    }
    return null;
  }
}

/// A media file referenced from a field.
enum MediaKind { audio, image }

class MediaReference {
  const MediaReference({required this.fileName, required this.kind});
  final String fileName;
  final MediaKind kind;
}

/// One named Anki field of a note.
class ImportedAnkiField {
  const ImportedAnkiField({
    required this.name,
    required this.ordinal,
    required this.rawValue,
    required this.plainTextValue,
    this.mediaReferences = const <MediaReference>[],
  });

  final String name;
  final int ordinal;

  /// The original field value, kept verbatim (may contain HTML/ruby/media).
  final String rawValue;

  /// A cleaned, human-readable version (best-effort).
  final String plainTextValue;
  final List<MediaReference> mediaReferences;
}

/// An imported Anki note with all of its named fields and tags.
class ImportedAnkiNote {
  const ImportedAnkiNote({
    required this.sourceNoteId,
    required this.sourceGuid,
    required this.sourceModelId,
    required this.modelName,
    required this.deckId,
    required this.fields,
    required this.tags,
  });

  final String sourceNoteId;
  final String sourceGuid;
  final String sourceModelId;
  final String modelName;
  final String deckId;
  final List<ImportedAnkiField> fields;
  final List<String> tags;

  ImportedAnkiField? fieldByName(String name) {
    for (final ImportedAnkiField f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }
}

/// A note type (Anki model): its fields and card templates.
class ImportedAnkiModel {
  const ImportedAnkiModel({
    required this.id,
    required this.name,
    required this.fieldNames,
    required this.templates,
  });

  final String id;
  final String name;

  /// Field names in ordinal order.
  final List<String> fieldNames;
  final List<ImportedAnkiCardTemplate> templates;

  ImportedAnkiCardTemplate? templateByOrdinal(int ord) {
    for (final ImportedAnkiCardTemplate t in templates) {
      if (t.ordinal == ord) return t;
    }
    return null;
  }
}

/// A card template from an Anki model (e.g. "Listening", "Reading").
class ImportedAnkiCardTemplate {
  const ImportedAnkiCardTemplate({
    required this.sourceModelId,
    required this.ordinal,
    required this.name,
    required this.questionTemplate,
    required this.answerTemplate,
  });

  final String sourceModelId;
  final int ordinal;
  final String name;
  final String questionTemplate;
  final String answerTemplate;
}

/// Links a generated Anki card to its source note + template + scheduling.
class ImportedAnkiCardSource {
  const ImportedAnkiCardSource({
    required this.sourceCardId,
    required this.sourceNoteId,
    required this.sourceDeckId,
    required this.templateOrdinal,
    this.templateName,
    required this.queueState,
    required this.due,
    required this.reps,
    required this.lapses,
  });

  final String sourceCardId;
  final String sourceNoteId;
  final String sourceDeckId;
  final int templateOrdinal;
  final String? templateName;
  final String queueState;
  final int due;
  final int reps;
  final int lapses;
}

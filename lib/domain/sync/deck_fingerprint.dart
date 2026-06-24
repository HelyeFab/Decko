// Cross-device review-state sync (MVP_022, DEC-031). A durable, deterministic
// identity for an imported deck so the same .apkg imported on two devices yields
// the same fingerprint — the only thing that lets review state attach safely.
// Framework-light.

import '../deck.dart';
import '../learning_item.dart';

class DeckFingerprint {
  const DeckFingerprint({
    required this.version,
    required this.sourceSystem,
    required this.sourceDeckName,
    required this.cardCount,
    required this.noteCount,
    required this.cardIdHash,
    required this.noteIdHash,
  });

  static const String currentVersion = 'v1';

  final String version;
  final String sourceSystem; // e.g. 'anki'
  final String sourceDeckName;
  final int cardCount;
  final int noteCount;

  /// FNV-1a hash of the sorted card ids — the strongest match signal.
  final String cardIdHash;

  /// FNV-1a hash of the sorted note ids.
  final String noteIdHash;

  /// The cloud document key — stable across devices, Firestore-safe (no '/').
  String get key => '$sourceSystem-$cardCount-$cardIdHash';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'sourceSystem': sourceSystem,
        'sourceDeckName': sourceDeckName,
        'cardCount': cardCount,
        'noteCount': noteCount,
        'cardIdHash': cardIdHash,
        'noteIdHash': noteIdHash,
      };

  static DeckFingerprint fromJson(Map<String, dynamic> m) => DeckFingerprint(
        version: m['version'] as String? ?? currentVersion,
        sourceSystem: m['sourceSystem'] as String? ?? 'anki',
        sourceDeckName: m['sourceDeckName'] as String? ?? '',
        cardCount: m['cardCount'] as int? ?? 0,
        noteCount: m['noteCount'] as int? ?? 0,
        cardIdHash: m['cardIdHash'] as String? ?? '',
        noteIdHash: m['noteIdHash'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is DeckFingerprint && other.key == key && other.noteIdHash == noteIdHash;

  @override
  int get hashCode => Object.hash(key, noteIdHash);
}

/// Builds a [DeckFingerprint] from an imported deck. Returns null for decks
/// without stable imported card identity (e.g. demo decks) — those never sync.
class DeckFingerprinter {
  const DeckFingerprinter();

  static const String _ankiPrefix = 'anki-card-';

  DeckFingerprint? fingerprint(Deck deck) {
    if (!deck.isImported || deck.items.isEmpty) return null;

    final List<String> cardIds = <String>[];
    final Set<String> noteIds = <String>{};
    for (final LearningItem item in deck.items) {
      // Only stable Anki card identities qualify.
      if (!item.id.startsWith(_ankiPrefix)) return null;
      cardIds.add(item.id);
      final String? noteId = item.importedProgress?.sourceNoteId;
      if (noteId != null && noteId.isNotEmpty) noteIds.add(noteId);
    }

    cardIds.sort();
    final List<String> sortedNotes = noteIds.toList()..sort();

    return DeckFingerprint(
      version: DeckFingerprint.currentVersion,
      sourceSystem: 'anki',
      sourceDeckName: deck.name,
      cardCount: cardIds.length,
      noteCount: sortedNotes.length,
      cardIdHash: _fnv1a(cardIds.join('|')),
      noteIdHash: _fnv1a(sortedNotes.join('|')),
    );
  }

  /// FNV-1a 64-bit, hex — deterministic across runs/devices (unlike hashCode).
  static String _fnv1a(String s) {
    int hash = 0xcbf29ce484222325;
    for (final int c in s.codeUnits) {
      hash = (hash ^ c) * 0x100000001b3;
    }
    return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }
}

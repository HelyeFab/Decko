import 'dart:typed_data';

import '../deck.dart';
import '../repositories/media_store.dart';
import 'deck_import_preview.dart';

/// Translates an external deck package into Decko's domain model.
///
/// Separates file parsing, preview, the user's keep/fresh choice, and deck
/// construction. The UI never parses packages directly — it talks to an adapter
/// (DEC-010). Implementations must fail with a [DeckImportException] rather than
/// throwing arbitrary errors, so the UI can always show a friendly message.
abstract class DeckImportAdapter {
  /// Inspects [bytes] and summarises what would be imported.
  Future<DeckImportPreview> preview(Uint8List bytes);

  /// Builds a Decko [Deck] from [bytes].
  ///
  /// When [keepProgress] is true, per-card imported progress is preserved;
  /// otherwise cards are imported as new. When [mediaStore] is provided, the
  /// package's media is extracted and saved under the new deck's id.
  Future<Deck> importDeck(
    Uint8List bytes, {
    required bool keepProgress,
    required DateTime importedAt,
    MediaStore? mediaStore,
  });
}

/// A handled, user-presentable import failure.
class DeckImportException implements Exception {
  const DeckImportException(this.message);
  final String message;
  @override
  String toString() => 'DeckImportException: $message';
}

/// The package format isn't supported yet (e.g. a modern zstd `.anki21b`).
class UnsupportedPackageException extends DeckImportException {
  const UnsupportedPackageException(super.message);
}

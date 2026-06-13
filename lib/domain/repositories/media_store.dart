import 'dart:typed_data';

/// Stores imported deck media (audio/images) on local disk, keyed by deck.
///
/// Behind an interface so the storage backend can evolve. Media blobs live on
/// the filesystem, never in `shared_preferences` (DEC-014).
abstract class MediaStore {
  /// Persists [bytes] for [fileName] under [deckId].
  Future<void> saveMedia(String deckId, String fileName, Uint8List bytes);

  /// The local file path for [fileName] in [deckId], or null if not stored.
  Future<String?> resolveMedia(String deckId, String fileName);

  /// Deletes all media for [deckId] (used when a deck is removed).
  Future<void> deleteMediaForDeck(String deckId);
}

import 'dart:typed_data';

/// Decompresses a raw Zstandard stream (MVP_013).
///
/// Abstracted so the adapter doesn't depend on a concrete codec: the app injects
/// a native-backed decoder, while tests inject a fake (the native `zstandard`
/// plugin can't run in host `flutter test`). Throws on malformed input.
abstract class ZstdDecoder {
  Future<Uint8List> decode(Uint8List input);
}

/// Thrown when zstd input can't be decompressed.
class ZstdDecodeException implements Exception {
  const ZstdDecodeException(this.message);
  final String message;
  @override
  String toString() => 'ZstdDecodeException: $message';
}

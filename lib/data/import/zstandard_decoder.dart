import 'dart:typed_data';

import 'package:zstandard/zstandard.dart';

import '../../domain/import/zstd_decoder.dart';

/// [ZstdDecoder] backed by the native `zstandard` plugin (MVP_013, DEC-022).
///
/// Used in the app to decompress modern Anki `collection.anki21b` and media.
/// Not used in host tests — those inject a fake decoder.
class ZstandardDecoder implements ZstdDecoder {
  const ZstandardDecoder();

  @override
  Future<Uint8List> decode(Uint8List input) async {
    final Uint8List? out = await Zstandard().decompress(input);
    if (out == null) {
      throw const ZstdDecodeException('zstd stream could not be decompressed');
    }
    return out;
  }
}

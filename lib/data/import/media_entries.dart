import 'dart:convert';
import 'dart:typed_data';

/// Reads filenames from Anki's `MediaEntries` protobuf — the media index used by
/// modern `.apkg` packages (MVP_013, DEC-022). Returns each entry's `name` in
/// order; the zip payload named `i` corresponds to `names[i]`. Hand-rolled (only
/// the `name` field is needed) so Decko avoids a protobuf dependency. On
/// malformed input it returns whatever it parsed, never throwing.
///
/// `MediaEntries { repeated MediaEntry entries = 1 }`
/// `MediaEntry   { string name = 1; uint32 size = 2; bytes sha1 = 3; … }`
List<String> parseMediaEntryNames(Uint8List bytes) {
  final List<String> names = <String>[];
  try {
    final _ProtoReader r = _ProtoReader(bytes);
    while (!r.atEnd) {
      final int tag = r.varint();
      if (tag >> 3 == 1 && (tag & 0x7) == 2) {
        names.add(_entryName(r.lengthDelimited()));
      } else {
        r.skip(tag & 0x7);
      }
    }
  } catch (_) {/* return partial */}
  return names;
}

String _entryName(Uint8List entry) {
  final _ProtoReader r = _ProtoReader(entry);
  while (!r.atEnd) {
    final int tag = r.varint();
    if (tag >> 3 == 1 && (tag & 0x7) == 2) {
      return utf8.decode(r.lengthDelimited(), allowMalformed: true);
    }
    r.skip(tag & 0x7);
  }
  return '';
}

class _ProtoReader {
  _ProtoReader(this._b);
  final Uint8List _b;
  int _i = 0;

  bool get atEnd => _i >= _b.length;

  int varint() {
    int result = 0;
    int shift = 0;
    while (true) {
      if (_i >= _b.length) throw const FormatException('varint eof');
      final int byte = _b[_i++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) break;
      shift += 7;
      if (shift > 63) throw const FormatException('varint too long');
    }
    return result;
  }

  Uint8List lengthDelimited() {
    final int len = varint();
    if (_i + len > _b.length) throw const FormatException('length eof');
    final Uint8List out = Uint8List.sublistView(_b, _i, _i + len);
    _i += len;
    return out;
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
      case 2:
        lengthDelimited();
      case 1:
        _i += 8;
      case 5:
        _i += 4;
      default:
        throw FormatException('unknown wire type $wire');
    }
  }
}

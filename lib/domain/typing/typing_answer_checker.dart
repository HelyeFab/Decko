import 'dart:math' as math;

import 'typing_recall.dart';

/// Judges a typed answer against a [TypingRecallRound] (MVP_021, DEC-030).
/// Deliberately explainable and conservative — it never silently accepts an
/// unrelated answer, and always lets the screen reveal the expected one.
///
/// - **correct**: matches any accepted answer after *safe* normalisation
///   (trim, collapse spaces, katakana→hiragana, full-width→half-width,
///   case-fold for English, strip surrounding punctuation).
/// - **almost**: not correct, but matches after *loose* normalisation (drop all
///   spaces + punctuation) or is a single-character typo on a longer answer.
/// - **incorrect**: otherwise.
class TypingRecallChecker {
  const TypingRecallChecker();

  // Punctuation treated as ignorable. Note: the long-vowel mark ー is NOT here —
  // it is meaningful in Japanese readings.
  static const String _punct =
      '。．.,，、！!？?；;：:…‥・／/「」『』（）()【】[]｛｝{}“”"‘’\'`~〜—–-＝=＋+＊*＆&％%＃#＠@';

  TypingResultCategory check(String input, TypingRecallRound round) {
    final bool english = round.targetKind == TypingTargetKind.meaning;

    final String safeInput = _safe(input, english);
    if (safeInput.isEmpty) return TypingResultCategory.incorrect;

    final List<String> safeAccepted = <String>[
      for (final String a in round.accepted)
        if (_safe(a, english).isNotEmpty) _safe(a, english),
    ];
    if (safeAccepted.contains(safeInput)) return TypingResultCategory.correct;

    // Almost — loose match (all spacing/punctuation dropped).
    final String looseInput = _loose(input, english);
    final List<String> looseAccepted = <String>[
      for (final String a in round.accepted)
        if (_loose(a, english).isNotEmpty) _loose(a, english),
    ];
    if (looseInput.isNotEmpty && looseAccepted.contains(looseInput)) {
      return TypingResultCategory.almost;
    }
    // Almost — a single-character typo on a reasonably long answer.
    for (final String a in safeAccepted) {
      if (a.length >= 4 && _levenshtein(safeInput, a) == 1) {
        return TypingResultCategory.almost;
      }
    }
    return TypingResultCategory.incorrect;
  }

  String _safe(String s, bool english) {
    String t = _normChars(s).trim();
    if (english) t = t.toLowerCase();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return _stripOuter(t).trim();
  }

  String _loose(String s, bool english) {
    String t = _normChars(s);
    if (english) t = t.toLowerCase();
    return _removeAllIgnorable(t);
  }

  /// Katakana → hiragana, full-width ASCII → half-width, ideographic space → space.
  String _normChars(String s) {
    final StringBuffer buf = StringBuffer();
    for (final int r in s.runes) {
      if (r >= 0x30A1 && r <= 0x30F6) {
        buf.writeCharCode(r - 0x60);
      } else if (r >= 0xFF01 && r <= 0xFF5E) {
        buf.writeCharCode(r - 0xFEE0);
      } else if (r == 0x3000) {
        buf.writeCharCode(0x20);
      } else {
        buf.writeCharCode(r);
      }
    }
    return buf.toString();
  }

  bool _ignorable(String ch) => ch.trim().isEmpty || _punct.contains(ch);

  String _stripOuter(String t) {
    int start = 0;
    int end = t.length;
    while (start < end && _ignorable(t[start])) {
      start++;
    }
    while (end > start && _ignorable(t[end - 1])) {
      end--;
    }
    return t.substring(start, end);
  }

  String _removeAllIgnorable(String t) {
    final StringBuffer buf = StringBuffer();
    for (final int rune in t.runes) {
      final String ch = String.fromCharCode(rune);
      if (!_ignorable(ch)) buf.write(ch);
    }
    return buf.toString();
  }

  int _levenshtein(String a, String b) {
    final List<int> prev = List<int>.generate(b.length + 1, (int i) => i);
    final List<int> curr = List<int>.filled(b.length + 1, 0);
    for (int i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final int cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = math.min(
          math.min(curr[j] + 1, prev[j + 1] + 1),
          prev[j] + cost,
        );
      }
      for (int j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }
}

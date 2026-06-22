// Small, framework-light helpers for preparing an imported field value before
// it is sent to the tokenizer service (MVP_016).

/// Strips Anki media markers (`[sound:…]`), bracketed furigana readings, HTML
/// tags, and `&nbsp;`, then collapses whitespace. The tokenizer service also
/// cleans furigana, but we strip `[sound:…]` here so audio is captured and not
/// sent as text.
String cleanSentence(String raw) {
  return raw
      .replaceAll(RegExp(r'\[sound:[^\]]*\]'), ' ')
      .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// The first `[sound:foo.mp3]` filename found in any of [candidates], or null.
String? soundRefIn(List<String?> candidates) {
  final RegExp re = RegExp(r'\[sound:([^\]]+)\]');
  for (final String? c in candidates) {
    if (c == null) continue;
    final RegExpMatch? m = re.firstMatch(c);
    if (m != null) return m.group(1);
  }
  return null;
}

/// A cheap, synchronous check that [sentence] is worth offering as a builder
/// round — used to decide entry-point visibility without calling the tokenizer.
/// The true token count is only known after tokenization.
bool looksLikeSentence(String? sentence) {
  if (sentence == null) return false;
  final String s = cleanSentence(sentence);
  if (s.runes.length < 4) return false;
  // Either spaced words (English) or contains Japanese script.
  return s.contains(' ') || s.runes.any(_isJapaneseRune);
}

bool _isJapaneseRune(int c) =>
    (c >= 0x3040 && c <= 0x30FF) ||
    c == 0x30FC ||
    (c >= 0x4E00 && c <= 0x9FFF) ||
    (c >= 0x3400 && c <= 0x4DBF);

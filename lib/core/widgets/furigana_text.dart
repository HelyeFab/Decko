import 'package:flutter/material.dart';

/// Renders Japanese text that may carry furigana in Anki bracket notation
/// (`漢字[かな]`), with the readings shown as ruby above the kanji.
///
/// When [showReadings] is false (or the text has no furigana) it renders plain
/// base text — so the same widget powers the furigana on/off toggle.
class FuriganaText extends StatelessWidget {
  const FuriganaText(
    this.text, {
    super.key,
    this.showReadings = true,
    this.baseStyle,
    this.readingStyle,
    this.align = TextAlign.start,
  });

  final String text;
  final bool showReadings;
  final TextStyle? baseStyle;
  final TextStyle? readingStyle;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final List<FuriToken> tokens = parseFurigana(text);
    final TextStyle base = baseStyle ?? DefaultTextStyle.of(context).style;

    final bool anyReadings = tokens.any((FuriToken t) => t.reading != null);
    if (!showReadings || !anyReadings) {
      return Text(
        tokens.map((FuriToken t) => t.base).join(),
        style: base,
        textAlign: align,
      );
    }

    final double baseSize = base.fontSize ?? 16;
    final TextStyle reading = readingStyle ??
        base.copyWith(
          fontSize: baseSize * 0.52,
          fontWeight: FontWeight.w400,
          height: 1.1,
          color: base.color?.withValues(alpha: 0.7),
        );

    return Wrap(
      alignment:
          align == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: <Widget>[
        for (final FuriToken t in tokens)
          if (t.reading == null)
            // Reserve the ruby line's height so bases sit on one baseline.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('​', style: reading),
                Text(t.base, style: base),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(t.reading!, style: reading),
                Text(t.base, style: base),
              ],
            ),
      ],
    );
  }
}

/// A run of text with an optional furigana reading.
class FuriToken {
  const FuriToken(this.base, this.reading);
  final String base;
  final String? reading;
}

final RegExp _bracket = RegExp(r'\[([^\]]*)\]');
final RegExp _trailingKanji = RegExp(r'[㐀-鿿々〆ヶ]+$');

/// Parses `漢字[かな]` notation into ordered base/reading tokens.
List<FuriToken> parseFurigana(String s) {
  final List<FuriToken> tokens = <FuriToken>[];
  int last = 0;
  for (final Match m in _bracket.allMatches(s)) {
    final String before = s.substring(last, m.start);
    final String reading = m.group(1) ?? '';
    final Match? kanji = _trailingKanji.firstMatch(before);
    if (kanji != null) {
      final String plain = before.substring(0, kanji.start);
      if (plain.isNotEmpty) tokens.add(FuriToken(plain, null));
      tokens.add(FuriToken(kanji.group(0)!, reading));
    } else if (before.isNotEmpty) {
      tokens.add(FuriToken(before, reading));
    }
    last = m.end;
  }
  if (last < s.length) tokens.add(FuriToken(s.substring(last), null));
  return tokens;
}

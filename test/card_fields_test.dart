// MVP_025: robust card-field extraction (handles media-only-front note types).

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/domain/card_fields.dart';
import 'package:decko/domain/learning_item.dart';

void main() {
  test('expression on the front: fields read straight through', () {
    const LearningItem item = LearningItem(
        id: 'a', front: '食べる', back: 'to eat', reading: 'たべる');
    final CardFields f = cardFieldsOf(item);
    expect(f.expression, '食べる');
    expect(f.meaning, 'to eat');
    expect(f.reading, 'たべる');
  });

  test('media-only front: expression + meaning come from the back lines', () {
    const LearningItem item = LearningItem(
      id: 'a',
      front: '[sound:8b0e.mp3] <img src="fefc.jpg">',
      back: 'それ\nthat, that one',
    );
    final CardFields f = cardFieldsOf(item);
    expect(f.expression, 'それ');
    expect(f.meaning, 'that, that one');
    expect(f.reading, isNull);
  });

  test('media-only front with a single back line: no meaning', () {
    const LearningItem item =
        LearningItem(id: 'a', front: '[sound:x.mp3]', back: '一');
    final CardFields f = cardFieldsOf(item);
    expect(f.expression, '一');
    expect(f.meaning, isEmpty);
  });
}

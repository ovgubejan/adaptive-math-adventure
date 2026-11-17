import 'package:adaptive_math_adventure/mechanics/matching_answer_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = MatchingAnswerCodec();

  test('encodes an identity arrangement as zero', () {
    expect(
      codec.encodeCompletedMapping(
        leftCardIds: ['number_2', 'number_3'],
        rightCardIds: ['apples_2', 'bananas_3'],
        matches: const {'number_2': 'apples_2', 'number_3': 'bananas_3'},
      ),
      0,
    );
  });

  test('encoding is independent of input and display ordering', () {
    final first = codec.encodeCompletedMapping(
      leftCardIds: ['c', 'a', 'b'],
      rightCardIds: ['z', 'x', 'y'],
      matches: const {'a': 'x', 'b': 'y', 'c': 'z'},
    );
    final reordered = codec.encodeCompletedMapping(
      leftCardIds: ['b', 'c', 'a'],
      rightCardIds: ['y', 'z', 'x'],
      matches: const {'c': 'z', 'b': 'y', 'a': 'x'},
    );
    expect(reordered, first);
  });

  test('all permutations of pair counts 2 through 5 have distinct codes', () {
    for (var pairCount = 2; pairCount <= 5; pairCount++) {
      final leftIds = [for (var i = 0; i < pairCount; i++) 'left_$i'];
      final rightIds = [for (var i = 0; i < pairCount; i++) 'right_$i'];
      final codes = <int>{};
      for (final permutation in _permutations(rightIds)) {
        final mapping = {
          for (var i = 0; i < pairCount; i++) leftIds[i]: permutation[i],
        };
        codes.add(
          codec.encodeCompletedMapping(
            leftCardIds: leftIds,
            rightCardIds: rightIds,
            matches: mapping,
          ),
        );
      }
      expect(codes, hasLength(_factorial(pairCount)));
      expect(
        codes,
        everyElement(inInclusiveRange(0, _factorial(pairCount) - 1)),
      );
    }
  });

  test('supports the maximum 18-pair web-safe boundary', () {
    final ids = [
      for (var i = 0; i < 18; i++) 'card_${i.toString().padLeft(2, '0')}',
    ];
    final identity = {for (final id in ids) id: id};
    final reverse = {
      for (var index = 0; index < ids.length; index++)
        ids[index]: ids[ids.length - index - 1],
    };

    expect(
      codec.encodeCompletedMapping(
        leftCardIds: ids,
        rightCardIds: ids,
        matches: identity,
      ),
      0,
    );
    expect(
      codec.encodeCompletedMapping(
        leftCardIds: ids,
        rightCardIds: ids,
        matches: reverse,
      ),
      _factorial(18) - 1,
    );
    expect(_factorial(18) - 1, lessThan(9007199254740991));
  });

  test('rejects invalid or incomplete mappings', () {
    void encode({
      List<String> left = const ['a', 'b'],
      List<String> right = const ['x', 'y'],
      Map<String, String> matches = const {'a': 'x', 'b': 'y'},
    }) => codec.encodeCompletedMapping(
      leftCardIds: left,
      rightCardIds: right,
      matches: matches,
    );

    expect(() => encode(matches: const {'a': 'x'}), throwsArgumentError);
    expect(
      () => encode(matches: const {'a': 'x', 'b': 'x'}),
      throwsArgumentError,
    );
    expect(
      () => encode(matches: const {'a': 'x', 'c': 'y'}),
      throwsArgumentError,
    );
    expect(() => encode(right: const ['x', 'x']), throwsArgumentError);
    expect(() => encode(left: const ['a']), throwsArgumentError);
    expect(
      () => encode(
        left: [for (var i = 0; i < 19; i++) 'l$i'],
        right: [for (var i = 0; i < 19; i++) 'r$i'],
        matches: {for (var i = 0; i < 19; i++) 'l$i': 'r$i'},
      ),
      throwsArgumentError,
    );
    expect(() => encode(left: const ['a', ' ']), throwsArgumentError);
  });
}

Iterable<List<T>> _permutations<T>(List<T> values) sync* {
  if (values.length <= 1) {
    yield List<T>.of(values);
    return;
  }
  for (var index = 0; index < values.length; index++) {
    final first = values[index];
    final remaining = List<T>.of(values)..removeAt(index);
    for (final tail in _permutations(remaining)) {
      yield [first, ...tail];
    }
  }
}

int _factorial(int value) {
  var result = 1;
  for (var factor = 2; factor <= value; factor++) {
    result *= factor;
  }
  return result;
}

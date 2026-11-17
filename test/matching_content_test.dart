import 'package:adaptive_math_adventure/content/matching_content.dart';
import 'package:adaptive_math_adventure/domain/activity_type.dart';
import 'package:adaptive_math_adventure/domain/math_question.dart';
import 'package:adaptive_math_adventure/mechanics/matching_answer_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses valid number-to-quantity content and freezes its collections',
    () {
      final content = MatchingContent.fromQuestion(_question());

      expect(content.prompt, 'Match each number with the correct quantity');
      expect(content.leftCards.map((card) => card.label), ['2', '3']);
      expect(content.rightCards.map((card) => card.quantity), [2, 3]);
      expect(content.correctPairs, const {
        'number_2': 'apples_2',
        'number_3': 'bananas_3',
      });
      expect(
        () =>
            content.leftCards.add(const MatchingLeftCard(id: 'x', label: 'x')),
        throwsUnsupportedError,
      );
      expect(
        () => content.correctPairs['number_2'] = 'bananas_3',
        throwsUnsupportedError,
      );
    },
  );

  test('rejects non-matching activity types', () {
    expect(
      () => MatchingContent.fromQuestion(
        MathQuestion(
          id: 'choice',
          levelId: 'test',
          activityType: ActivityType.counting,
          skillTag: 'counting',
          difficulty: 1,
          data: _baseData(),
          correctAnswer: 0,
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects duplicate card IDs and unequal card counts', () {
    expect(
      () => MatchingContent.fromQuestion(
        _question(data: _baseData(leftIds: const ['number_2', 'number_2'])),
      ),
      throwsFormatException,
    );
    expect(
      () => MatchingContent.fromQuestion(
        _question(data: _baseData(rightIds: const ['apples_2'])),
      ),
      throwsFormatException,
    );
  });

  test('rejects pair counts outside 2 through 6', () {
    expect(
      () => MatchingContent.fromQuestion(
        _question(
          data: _baseData(
            leftIds: const ['number_2'],
            rightIds: const ['apples_2'],
            correct: const {'number_2': 'apples_2'},
          ),
        ),
      ),
      throwsFormatException,
    );
    final left = [for (var index = 0; index < 7; index++) 'left_$index'];
    final right = [for (var index = 0; index < 7; index++) 'right_$index'];
    final pairs = {
      for (var index = 0; index < 7; index++) left[index]: right[index],
    };
    expect(
      () => MatchingContent.fromQuestion(
        _question(
          data: _baseData(leftIds: left, rightIds: right, correct: pairs),
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects missing, duplicate, and unknown correct pair IDs', () {
    expect(
      () => MatchingContent.fromQuestion(
        _question(data: _baseData(correct: const {'number_2': 'apples_2'})),
      ),
      throwsFormatException,
    );
    expect(
      () => MatchingContent.fromQuestion(
        _question(
          data: _baseData(
            pairList: const [
              {'leftId': 'number_2', 'rightId': 'apples_2'},
              {'leftId': 'number_2', 'rightId': 'bananas_3'},
            ],
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => MatchingContent.fromQuestion(
        _question(
          data: _baseData(
            correct: const {'number_2': 'unknown', 'number_3': 'bananas_3'},
          ),
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects invalid quantity and answer-code mismatch', () {
    expect(
      () => MatchingContent.fromQuestion(
        _question(data: _baseData(quantities: const [0, 3])),
      ),
      throwsFormatException,
    );
    expect(
      () => MatchingContent.fromQuestion(_question(correctAnswer: 1)),
      throwsFormatException,
    );
  });
}

MathQuestion _question({Map<String, Object>? data, int? correctAnswer}) =>
    MathQuestion(
      id: 'matching-test',
      levelId: 'test-level',
      activityType: ActivityType.matching,
      skillTag: 'number-quantity',
      difficulty: 1,
      data: data ?? _baseData(),
      correctAnswer: correctAnswer ?? _expectedCode(),
    );

Map<String, Object> _baseData({
  List<String> leftIds = const ['number_2', 'number_3'],
  List<String> rightIds = const ['apples_2', 'bananas_3'],
  List<int> quantities = const [2, 3],
  Map<String, String> correct = const {
    'number_2': 'apples_2',
    'number_3': 'bananas_3',
  },
  List<Map<String, String>>? pairList,
}) => {
  'prompt': 'Match each number with the correct quantity',
  'leftCards': [
    for (var index = 0; index < leftIds.length; index++)
      {'id': leftIds[index], 'label': '${index + 2}'},
  ],
  'rightCards': [
    for (var index = 0; index < rightIds.length; index++)
      {
        'id': rightIds[index],
        'visual': index == 0 ? 'apple' : 'banana',
        'quantity': index < quantities.length ? quantities[index] : 1,
      },
  ],
  'correctPairs':
      pairList ??
      [
        for (final entry in correct.entries)
          {'leftId': entry.key, 'rightId': entry.value},
      ],
};

int _expectedCode() => const MatchingAnswerCodec().encodeCompletedMapping(
  leftCardIds: const ['number_2', 'number_3'],
  rightCardIds: const ['apples_2', 'bananas_3'],
  matches: const {'number_2': 'apples_2', 'number_3': 'bananas_3'},
);

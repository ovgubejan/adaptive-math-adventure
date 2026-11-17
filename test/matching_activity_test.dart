import 'package:adaptive_math_adventure/domain/activity_type.dart';
import 'package:adaptive_math_adventure/domain/math_question.dart';
import 'package:adaptive_math_adventure/mechanics/matching_activity.dart';
import 'package:adaptive_math_adventure/mechanics/matching_answer_codec.dart';
import 'package:adaptive_math_adventure/presentation/counting_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = CountingTheme.themes.first;

  testWidgets('renders valid matching content and card groups', (tester) async {
    await tester.pumpWidget(_app(theme: theme, onAnswer: (_) {}));

    expect(find.byType(MatchingActivity), findsOneWidget);
    expect(
      find.text('Match each number with the correct quantity'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('matching-left-number_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('matching-right-apples_2')),
      findsOneWidget,
    );
    expect(find.text('🍎'), findsNWidgets(2));
    expect(find.text('🍌'), findsNWidgets(3));
  });

  testWidgets(
    'taps select cards with visual feedback and do not submit pairs',
    (tester) async {
      final answers = <int>[];
      await tester.pumpWidget(_app(theme: theme, onAnswer: answers.add));

      await tester.tap(find.byKey(const ValueKey('matching-left-number_2')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('matching-left-selected-number_2')),
        findsOneWidget,
      );
      expect(answers, isEmpty);

      await tester.tap(find.byKey(const ValueKey('matching-right-apples_2')));
      await tester.pump();
      expect(find.text('Matches: 1 of 2'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('matching-left-matched-number_2')),
        findsOneWidget,
      );
      expect(answers, isEmpty);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('matching-submit')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('complete arrangement submits one integer exactly once', (
    tester,
  ) async {
    final answers = <int>[];
    await tester.pumpWidget(_app(theme: theme, onAnswer: answers.add));

    await _tapPair(tester, 'number_2', 'apples_2');
    await _tapPair(tester, 'number_3', 'bananas_3');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('matching-submit')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('matching-submit')));
    await tester.pump();
    expect(answers, [0]);
    expect(answers.single, isA<int>());

    await tester.tap(find.byKey(const ValueKey('matching-submit')));
    await tester.tap(find.byKey(const ValueKey('matching-left-number_2')));
    await tester.pump();
    expect(answers, [0]);
  });

  testWidgets('answerLocked disables card interaction and submission', (
    tester,
  ) async {
    final answers = <int>[];
    await tester.pumpWidget(
      _app(theme: theme, onAnswer: answers.add, answerLocked: true),
    );

    await tester.tap(find.byKey(const ValueKey('matching-left-number_2')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('matching-left-selected-number_2')),
      findsNothing,
    );
    expect(answers, isEmpty);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('matching-submit')))
          .onPressed,
      isNull,
    );
  });
}

Future<void> _tapPair(WidgetTester tester, String left, String right) async {
  await tester.tap(find.byKey(ValueKey('matching-left-$left')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('matching-right-$right')));
  await tester.pump();
}

Widget _app({
  required CountingTheme theme,
  required ValueChanged<int> onAnswer,
  bool answerLocked = false,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: MatchingActivity(
        question: _question(),
        theme: theme,
        onAnswer: onAnswer,
        answerLocked: answerLocked,
      ),
    ),
  ),
);

MathQuestion _question() => MathQuestion(
  id: 'matching-widget-test',
  levelId: 'test-level',
  activityType: ActivityType.matching,
  skillTag: 'number-quantity',
  difficulty: 1,
  correctAnswer: const MatchingAnswerCodec().encodeCompletedMapping(
    leftCardIds: const ['number_2', 'number_3'],
    rightCardIds: const ['apples_2', 'bananas_3'],
    matches: const {'number_2': 'apples_2', 'number_3': 'bananas_3'},
  ),
  data: const {
    'prompt': 'Match each number with the correct quantity',
    'leftCards': [
      {'id': 'number_2', 'label': '2'},
      {'id': 'number_3', 'label': '3'},
    ],
    'rightCards': [
      {'id': 'apples_2', 'visual': 'apple', 'quantity': 2},
      {'id': 'bananas_3', 'visual': 'banana', 'quantity': 3},
    ],
    'correctPairs': [
      {'leftId': 'number_2', 'rightId': 'apples_2'},
      {'leftId': 'number_3', 'rightId': 'bananas_3'},
    ],
  },
);

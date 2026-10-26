import 'package:adaptive_math_adventure/content/question_repository.dart';
import 'package:adaptive_math_adventure/domain/activity_content.dart';
import 'package:adaptive_math_adventure/domain/activity_type.dart';
import 'package:adaptive_math_adventure/domain/level_definition.dart';
import 'package:adaptive_math_adventure/domain/math_question.dart';
import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/mechanics/activity_renderer.dart';
import 'package:adaptive_math_adventure/mechanics/counting_activity.dart';
import 'package:adaptive_math_adventure/mechanics/drag_drop_activity.dart';
import 'package:adaptive_math_adventure/mechanics/multiple_choice_activity.dart';
import 'package:adaptive_math_adventure/persistence/session_result_persistence.dart';
import 'package:adaptive_math_adventure/presentation/counting_theme.dart';
import 'package:adaptive_math_adventure/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryPersistence implements SessionResultPersistence {
  final List<SessionResult> saved = [];

  @override
  Future<List<SessionResult>> loadResults() async => List.of(saved);

  @override
  Future<void> saveResult(SessionResult result) async => saved.add(result);
}

class _UnsupportedQuestions extends QuestionRepository {
  @override
  List<MathQuestion> questionsFor(LevelDefinition level) => List.generate(
    5,
    (index) => MathQuestion(
      id: 'unsupported-$index',
      levelId: 'level-01',
      activityType: ActivityType.matching,
      skillTag: 'matching',
      difficulty: 1,
      data: const {
        'prompt': 'Match these',
        'answerOptions': [1, 2],
      },
      correctAnswer: 1,
    ),
  );
}

void main() {
  final demoTheme = CountingTheme.themes.first;

  Future<SessionController> startDemo(_MemoryPersistence persistence) async {
    final controller = SessionController(
      questionRepository: QuestionRepository(),
      persistence: persistence,
    );
    await controller.startDemoSession();
    return controller;
  }

  Future<void> showActivity(
    WidgetTester tester,
    SessionController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => ActivityRenderer(
                question: controller.currentQuestion!,
                theme: demoTheme,
                onAnswer: controller.submitAnswer,
                answerLocked: controller.canAdvance,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> advanceToDrag(
    WidgetTester tester,
    SessionController controller,
  ) async {
    await showActivity(tester, controller);
    expect(find.byType(MultipleChoiceActivity), findsOneWidget);
    controller.submitAnswer(5);
    await tester.pumpAndSettle();
    await controller.advance();
    controller.submitAnswer(5);
    await controller.advance();
    await showActivity(tester, controller);
    expect(find.byType(DragDropActivity), findsOneWidget);
  }

  testWidgets('renderer keeps counting and selects multiple choice options', (
    tester,
  ) async {
    final persistence = _MemoryPersistence();
    final controller = await startDemo(persistence);
    addTearDown(controller.dispose);
    await showActivity(tester, controller);

    expect(find.byType(MultipleChoiceActivity), findsOneWidget);
    expect(find.text('3 + 2 = ?'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('multiple-choice-5')));
    await tester.pump();
    expect(controller.currentAttempts.single.answer, 5);
    expect(controller.currentAttempts.single.isCorrect, isTrue);
  });

  testWidgets('counting remains the renderer for Level 1 content', (
    tester,
  ) async {
    final persistence = _MemoryPersistence();
    final controller = SessionController(
      questionRepository: QuestionRepository(),
      persistence: persistence,
    );
    addTearDown(controller.dispose);
    await controller.startSession('level-01');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityRenderer(
            question: controller.currentQuestion!,
            theme: demoTheme,
            onAnswer: controller.submitAnswer,
          ),
        ),
      ),
    );
    expect(find.byType(CountingActivity), findsOneWidget);
    expect(find.byIcon(demoTheme.objectIcon), findsNWidgets(3));
  });

  testWidgets('multiple-choice incorrect selection is recorded', (
    tester,
  ) async {
    final controller = await startDemo(_MemoryPersistence());
    addTearDown(controller.dispose);
    await showActivity(tester, controller);

    await tester.tap(find.byKey(const ValueKey('multiple-choice-4')));
    await tester.pump();

    expect(controller.currentAttempts.single.answer, 4);
    expect(controller.currentAttempts.single.isCorrect, isFalse);
  });

  for (final testCase in [
    (answer: 3, correct: true, description: 'correct'),
    (answer: 2, correct: false, description: 'incorrect'),
  ]) {
    testWidgets(
      'drag and drop records ${testCase.description} submitted value',
      (tester) async {
        final persistence = _MemoryPersistence();
        final controller = await startDemo(persistence);
        addTearDown(controller.dispose);
        await advanceToDrag(tester, controller);

        final source = find.byKey(ValueKey('drag-answer-${testCase.answer}'));
        final target = find.byKey(const ValueKey('drag-answer-target'));
        await tester.drag(
          source,
          tester.getCenter(target) - tester.getCenter(source),
        );
        await tester.pumpAndSettle();

        expect(controller.currentAttempts, hasLength(1));
        expect(controller.currentAttempts.single.answer, testCase.answer);
        expect(controller.currentAttempts.single.isCorrect, testCase.correct);
      },
    );
  }

  testWidgets('drag activity prevents duplicate submissions', (tester) async {
    final persistence = _MemoryPersistence();
    final controller = await startDemo(persistence);
    addTearDown(controller.dispose);
    await advanceToDrag(tester, controller);

    final source = find.byKey(const ValueKey('drag-answer-3'));
    final target = find.byKey(const ValueKey('drag-answer-target'));
    await tester.drag(
      source,
      tester.getCenter(target) - tester.getCenter(source),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('drag-answer-2')));
    await tester.tap(find.byKey(const ValueKey('submit-selected-answer')));

    expect(controller.currentAttempts, hasLength(1));
    expect(controller.currentAttempts.single.answer, 3);
  });

  testWidgets('drag activity tap-to-select alternative submits answer', (
    tester,
  ) async {
    final persistence = _MemoryPersistence();
    final controller = await startDemo(persistence);
    addTearDown(controller.dispose);
    await advanceToDrag(tester, controller);

    await tester.tap(find.byKey(const ValueKey('drag-answer-3')));
    await tester.pump();
    expect(controller.currentAttempts, isEmpty);

    await tester.tap(find.byKey(const ValueKey('submit-selected-answer')));
    await tester.pumpAndSettle();
    expect(controller.currentAttempts.single.answer, 3);
    expect(controller.currentAttempts.single.isCorrect, isTrue);
  });

  test('unsupported activity type fails session setup safely', () async {
    final controller = SessionController(
      questionRepository: _UnsupportedQuestions(),
      persistence: _MemoryPersistence(),
    );
    addTearDown(controller.dispose);

    await controller.startSession('level-01');
    expect(controller.status, SessionStatus.failed);
    expect(controller.currentQuestion, isNull);
    expect(controller.errorMessage, contains('not supported yet'));
  });

  testWidgets('all rendered activity types submit compatible attempt records', (
    tester,
  ) async {
    final persistence = _MemoryPersistence();
    final countingController = SessionController(
      questionRepository: QuestionRepository(),
      persistence: persistence,
    );
    await countingController.startSession('level-01');
    countingController.submitAnswer(
      countingController.currentQuestion!.correctAnswer,
    );
    final countingAttempt = countingController.currentAttempts.single;
    expect(countingAttempt.answer, isA<int>());
    expect(countingAttempt.isCorrect, isTrue);
    expect(countingAttempt.responseTime, isA<Duration>());
    countingController.dispose();

    final controller = await startDemo(persistence);
    addTearDown(controller.dispose);

    await showActivity(tester, controller);
    controller.submitAnswer(5);
    await controller.advance();
    await showActivity(tester, controller);
    controller.submitAnswer(4);
    await controller.advance();
    await showActivity(tester, controller);
    controller.submitAnswer(3);
    expect(controller.currentAttempts.single.isCorrect, isTrue);

    await controller.advance();
    expect(controller.status, SessionStatus.completed);
    expect(controller.result!.evidence, hasLength(3));
    expect(
      controller.result!.evidence.map((item) => item.attempts.single.answer),
      [5, 4, 3],
    );
    expect(persistence.saved, hasLength(1));
    expect(controller.assessmentDecision, isNotNull);
    expect(controller.assessmentDecision!.hasSufficientEvidence, isTrue);
  });

  test('invalid mechanic configuration is rejected', () {
    const invalid = MathQuestion(
      id: 'bad-multiple-choice',
      levelId: 'activity-demo',
      activityType: ActivityType.multipleChoice,
      skillTag: 'addition',
      difficulty: 1,
      data: {
        'prompt': '2 + 2 = ?',
        'answerOptions': [3, 5],
      },
      correctAnswer: 4,
    );
    expect(() => ActivityContent.fromQuestion(invalid), throwsFormatException);
  });
}

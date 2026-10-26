import 'package:adaptive_math_adventure/content/question_repository.dart';
import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/persistence/session_result_persistence.dart';
import 'package:adaptive_math_adventure/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryResultPersistence implements SessionResultPersistence {
  final List<SessionResult> saved = [];

  @override
  Future<List<SessionResult>> loadResults() async => List.of(saved);

  @override
  Future<void> saveResult(SessionResult result) async =>
      saved.insert(0, result);
}

void main() {
  late MemoryResultPersistence persistence;
  late DateTime now;
  late SessionController controller;

  setUp(() {
    persistence = MemoryResultPersistence();
    now = DateTime.utc(2026, 1, 1);
    controller = SessionController(
      questionRepository: QuestionRepository(),
      persistence: persistence,
      clock: () => now,
    );
  });

  tearDown(() => controller.dispose());

  test('starts a five-question counting session', () async {
    await controller.startSession('level-01');

    expect(controller.status, SessionStatus.active);
    expect(controller.questionCount, 5);
    expect(controller.currentIndex, 0);
    expect(controller.currentQuestion?.id, 'count-01');
  });

  test(
    'records incorrect and correct attempts with timing and hints',
    () async {
      await controller.startSession('level-01');
      now = now.add(const Duration(seconds: 2));
      controller.recordHintUsage();

      expect(controller.submitAnswer(99), isFalse);
      final incorrect = controller.currentAttempts.single;
      expect(incorrect.answer, 99);
      expect(incorrect.isCorrect, isFalse);
      expect(incorrect.responseTime, const Duration(seconds: 2));
      expect(incorrect.hintUsed, isTrue);

      await controller.advance();
      now = now.add(const Duration(milliseconds: 850));
      expect(controller.submitAnswer(5), isTrue);
      final correct = controller.currentAttempts.single;
      expect(correct.isCorrect, isTrue);
      expect(correct.hintUsed, isFalse);
      expect(correct.responseTime, const Duration(milliseconds: 850));
    },
  );

  test(
    'completes after five questions and persists adaptive evidence',
    () async {
      await controller.startSession('level-01');
      for (var index = 0; index < 5; index++) {
        controller.submitAnswer(controller.currentQuestion!.correctAnswer);
        if (index < 4) {
          await controller.advance();
        }
      }
      await controller.advance();

      expect(controller.status, SessionStatus.completed);
      expect(controller.result, isNotNull);
      expect(controller.result!.totalQuestions, 5);
      expect(controller.result!.correctCount, 5);
      expect(controller.result!.accuracy, 1);
      expect(controller.result!.evidence, hasLength(5));
      expect(controller.result!.evidence.first.skillTag, 'counting-small-sets');
      expect(controller.result!.evidence.first.difficulty, 1);
      expect(
        controller.result!.evidence.first.attempts.single.responseTime,
        Duration.zero,
      );
      expect(persistence.saved.single.sessionId, controller.result!.sessionId);
    },
  );

  test(
    'unknown and locked level IDs fail without starting a session',
    () async {
      await controller.startSession('missing-level');
      expect(controller.status, SessionStatus.failed);
      expect(
        controller.errorMessage,
        contains('unknown, locked, or unavailable'),
      );

      await controller.startSession('level-02');
      expect(controller.status, SessionStatus.failed);
      expect(controller.questionCount, 0);
    },
  );
}

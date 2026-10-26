import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/persistence/local_session_result_persistence.dart';
import 'package:adaptive_math_adventure/progress/session_history_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('completed session summary survives reopening persistence', () async {
    SharedPreferences.setMockInitialValues({});
    final firstRun = LocalSessionResultPersistence();
    final result = SessionResult(
      sessionId: 'level-01-session-1',
      levelId: 'level-01',
      startedAt: DateTime.utc(2026, 1, 1),
      completedAt: DateTime.utc(2026, 1, 1, 0, 1),
      evidence: const [
        QuestionEvidence(
          questionId: 'count-01',
          skillTag: 'counting-small-sets',
          difficulty: 1,
          attempts: [
            AnswerAttempt(
              answer: 3,
              isCorrect: true,
              responseTime: Duration(seconds: 2),
              hintUsed: false,
            ),
          ],
        ),
      ],
    );
    await firstRun.saveResult(result);

    final reopenedPersistence = LocalSessionResultPersistence();
    final history = SessionHistoryController(reopenedPersistence);
    await history.load();

    expect(history.latestResult?.sessionId, result.sessionId);
    expect(history.latestResult?.correctCount, 1);
    expect(
      history.latestResult?.evidence.single.attempts.single.responseTime,
      const Duration(seconds: 2),
    );
  });
}

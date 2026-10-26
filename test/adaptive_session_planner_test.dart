import 'package:adaptive_math_adventure/content/level_catalog.dart';
import 'package:adaptive_math_adventure/content/question_repository.dart';
import 'package:adaptive_math_adventure/domain/adaptive_assessment.dart';
import 'package:adaptive_math_adventure/domain/level_definition.dart';
import 'package:adaptive_math_adventure/domain/math_question.dart';
import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/persistence/local_adaptive_progress_repository.dart';
import 'package:adaptive_math_adventure/persistence/memory_adaptive_progress_repository.dart';
import 'package:adaptive_math_adventure/persistence/session_result_persistence.dart';
import 'package:adaptive_math_adventure/session/adaptive_session_planner.dart';
import 'package:adaptive_math_adventure/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final level = LevelCatalog.byId('level-01')!;
  final bank = QuestionRepository().questionsFor(level);
  const planner = AdaptiveSessionPlanner();

  test('Level 1 bank has curated content across three difficulty bands', () {
    expect(bank.length, inInclusiveRange(30, 45));
    expect(bank.map((question) => question.difficulty).toSet(), {1, 2, 3});
  });

  test('new learners receive five Easy questions', () {
    final plan = _plan(
      planner,
      level,
      bank,
      difficulty: AdaptiveDifficulty.easy,
    );

    expect(plan.questions, hasLength(5));
    expect(
      plan.questions.every((question) => question.difficulty == 1),
      isTrue,
    );
    expect(plan.plannedDifficulty, 1);
  });

  test('strong and struggling recommendations change planned difficulty', () {
    final strong = _plan(
      planner,
      level,
      bank,
      difficulty: AdaptiveDifficulty.hard,
      mastery: 90,
    );
    final struggling = _plan(
      planner,
      level,
      bank,
      difficulty: AdaptiveDifficulty.easy,
      mastery: 35,
    );

    expect(
      strong.questions.every((question) => question.difficulty == 3),
      isTrue,
    );
    expect(
      struggling.questions.every((question) => question.difficulty == 1),
      isTrue,
    );
  });

  test('focus skill receives additional representation', () {
    final focused = _plan(
      planner,
      level,
      bank,
      difficulty: AdaptiveDifficulty.easy,
      focus: 'counting-small-sets',
    );
    final unfocused = _plan(
      planner,
      level,
      bank,
      difficulty: AdaptiveDifficulty.easy,
    );

    expect(
      focused.questions
          .where((question) => question.skillTag == 'counting-small-sets')
          .length,
      greaterThan(
        unfocused.questions
            .where((question) => question.skillTag == 'counting-small-sets')
            .length,
      ),
    );
  });

  test('recent questions are avoided when enough alternatives exist', () {
    final recentlySeen = bank.take(5).map((question) => question.id).toList();
    final plan = planner.plan(
      level: level,
      questionBank: bank,
      previousMastery: 50,
      recommendedDifficulty: AdaptiveDifficulty.easy,
      focusSkill: null,
      recentQuestionIds: recentlySeen,
      randomSeed: 5,
    );

    expect(
      plan.questions.map((question) => question.id),
      isNot(containsAll(recentlySeen)),
    );
  });

  test('same seed and history produce the same unique question IDs', () {
    final first = _plan(planner, level, bank, seed: 17);
    final second = _plan(planner, level, bank, seed: 17);

    expect(first.selectedQuestionIds, second.selectedQuestionIds);
    expect(first.selectedQuestionIds.toSet(), hasLength(5));
  });

  test(
    'selection is limited to the selected level and configured mechanics',
    () {
      final plan = planner.plan(
        level: level,
        questionBank: [...bank, ...QuestionRepository.demoQuestions],
        previousMastery: 0,
        recommendedDifficulty: AdaptiveDifficulty.easy,
        focusSkill: null,
        recentQuestionIds: const [],
        randomSeed: 2,
      );

      expect(plan.questions, hasLength(5));
      expect(
        plan.questions.every((question) => question.levelId == level.id),
        isTrue,
      );
      expect(
        plan.questions.every(
          (question) =>
              level.availableActivityTypes.contains(question.activityType),
        ),
        isTrue,
      );
    },
  );

  test('empty and undersized eligible banks fail explicitly', () {
    expect(
      () => planner.plan(
        level: level,
        questionBank: const [],
        previousMastery: 0,
        recommendedDifficulty: AdaptiveDifficulty.easy,
        focusSkill: null,
        recentQuestionIds: const [],
      ),
      throwsA(isA<SessionPlanningException>()),
    );
    expect(
      () => planner.plan(
        level: level,
        questionBank: bank.take(4).toList(),
        previousMastery: 0,
        recommendedDifficulty: AdaptiveDifficulty.easy,
        focusSkill: null,
        recentQuestionIds: const [],
      ),
      throwsA(isA<SessionPlanningException>()),
    );
  });

  test('difficulty and focus fallbacks are reported explicitly', () {
    final plan = planner.plan(
      level: level,
      questionBank: bank.take(5).toList(),
      previousMastery: 20,
      recommendedDifficulty: AdaptiveDifficulty.hard,
      focusSkill: 'not-in-level-bank',
      recentQuestionIds: bank.take(5).map((question) => question.id).toList(),
      randomSeed: 31,
    );

    expect(plan.questions, hasLength(5));
    expect(plan.usedFallback, isTrue);
    expect(plan.fallbacks.join(' '), contains('focus skill'));
    expect(plan.fallbacks.join(' '), contains('Reused older questions'));
    expect(plan.fallbacks.join(' '), contains('adjacent difficulty bands'));
  });

  test('saved adaptive state shapes the following session', () async {
    final progress = MemoryAdaptiveProgressRepository();
    final persistence = _MemoryResultPersistence();
    final firstPlan = _plan(planner, level, bank, seed: 42);
    final controller = SessionController(
      questionRepository: QuestionRepository(),
      persistence: persistence,
      adaptiveProgressRepository: progress,
      clock: () => DateTime.utc(2026, 1, 1),
    );

    await controller.startPlannedSession(level.id, firstPlan.questions);
    for (var index = 0; index < 5; index++) {
      controller.submitAnswer(controller.currentQuestion!.correctAnswer);
      await controller.advance();
    }

    final saved = (await progress.loadAll()).single;
    final secondPlan = planner.plan(
      level: level,
      questionBank: bank,
      previousMastery: saved.mastery,
      recommendedDifficulty: saved.currentDifficulty,
      focusSkill: saved.latestFocusSkill,
      recentQuestionIds: saved.recentQuestionIds,
      randomSeed: 43,
    );

    expect(saved.currentDifficulty, AdaptiveDifficulty.medium);
    expect(
      saved.recentQuestionIds.toSet().containsAll(
        firstPlan.selectedQuestionIds,
      ),
      isTrue,
    );
    expect(
      secondPlan.questions.every((question) => question.difficulty == 2),
      isTrue,
    );
    expect(
      secondPlan.questions
          .map((question) => question.id)
          .toSet()
          .intersection(firstPlan.selectedQuestionIds.toSet()),
      isEmpty,
    );
    controller.dispose();
  });

  test(
    'recommended difficulty and recent IDs survive progress reload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalAdaptiveProgressRepository();
      await repository.save(
        AdaptiveProgressState(
          levelId: level.id,
          mastery: 0,
          currentDifficulty: AdaptiveDifficulty.medium,
          completedSessionCount: 0,
          recentSessionScores: const [],
          masterySnapshots: const [],
          skillPerformance: const {},
          completedSessionIds: const [],
          successfulMediumSessionCount: 0,
          completedLevelIds: const [],
          recentQuestionIds: const ['count-01', 'count-02'],
        ),
      );

      final reopened = LocalAdaptiveProgressRepository();
      final restored = (await reopened.loadAll()).single;

      expect(restored.currentDifficulty, AdaptiveDifficulty.medium);
      expect(restored.recentQuestionIds, ['count-01', 'count-02']);
    },
  );
}

AdaptiveSessionPlan _plan(
  AdaptiveSessionPlanner planner,
  LevelDefinition level,
  List<MathQuestion> questions, {
  AdaptiveDifficulty difficulty = AdaptiveDifficulty.easy,
  double mastery = 0,
  String? focus,
  int seed = 0,
}) => planner.plan(
  level: level,
  questionBank: questions,
  previousMastery: mastery,
  recommendedDifficulty: difficulty,
  focusSkill: focus,
  recentQuestionIds: const [],
  randomSeed: seed,
);

class _MemoryResultPersistence implements SessionResultPersistence {
  final List<SessionResult> results = [];

  @override
  Future<List<SessionResult>> loadResults() async => List.of(results);

  @override
  Future<void> saveResult(SessionResult result) async => results.add(result);
}

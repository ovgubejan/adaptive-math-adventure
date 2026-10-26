import 'package:adaptive_math_adventure/domain/adaptive_assessment.dart';
import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/persistence/local_adaptive_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const engine = AdaptiveAssessmentEngine();

  test('weighted accuracy uses normalized difficulty weights', () {
    final decision = engine.evaluate(
      _result('weighted', [
        _question('easy', 1, [false]),
        _question('hard', 3, [true]),
      ]),
    );

    expect(decision.scoreComponents.weightedAccuracy, closeTo(58.333, 0.001));
    expect(decision.sessionScore, closeTo(66.667, 0.001));
  });

  test(
    'scores stay within 0–100 for all-correct and all-incorrect evidence',
    () {
      final allCorrect = engine.evaluate(
        _result('all-correct', [
          _question('easy', 1, [true]),
        ]),
      );
      final allIncorrect = engine.evaluate(
        _result('all-incorrect', [
          _question('easy', 1, [false]),
        ]),
      );

      expect(allCorrect.sessionScore, 100);
      expect(allIncorrect.sessionScore, 20);
      expect(allCorrect.sessionScore, inInclusiveRange(0, 100));
      expect(allIncorrect.sessionScore, inInclusiveRange(0, 100));
    },
  );

  test('hinted, mixed, and incomplete evidence are handled explicitly', () {
    final hinted = engine.evaluate(
      _result('hinted', [
        _question('one', 1, [true], hints: [true]),
      ]),
    );
    final mixed = engine.evaluate(
      _result('mixed', [
        _question('one', 1, [true, false]),
      ]),
    );
    final incomplete = engine.evaluate(
      _result('incomplete', [
        _question('answered', 1, [true]),
        _question('missing', 1, []),
      ]),
    );

    expect(hinted.scoreComponents.hintIndependence, 0);
    expect(hinted.sessionScore, 90);
    expect(mixed.scoreComponents.weightedAccuracy, 50);
    expect(incomplete.hasSufficientEvidence, isFalse);
    expect(incomplete.sessionScore, isNotNull);
    expect(incomplete.newMastery, 0);
    expect(
      incomplete.diagnostics.any((item) => item.contains('incomplete')),
      isTrue,
    );
    final legacy = engine.evaluate(
      SessionResult(
        sessionId: 'legacy-result',
        levelId: 'level-test',
        startedAt: DateTime.utc(2026, 1, 1),
        completedAt: DateTime.utc(2026, 1, 1, 0, 1),
        evidence: [
          _question('old-question', 1, [true]),
        ],
      ),
    );
    expect(legacy.hasSufficientEvidence, isFalse);
    expect(
      legacy.diagnostics.any((item) => item.contains('legacy session result')),
      isTrue,
    );
    final noAnswers = engine.evaluate(
      _result('no-answers', [_question('unanswered', 1, [])]),
    );
    expect(noAnswers.sessionScore, isNull);
    expect(noAnswers.scoreComponents.weightedAccuracy, isNull);
    expect(noAnswers.hasSufficientEvidence, isFalse);
  });

  test('response efficiency defaults to neutral and is configurable', () {
    final result = _result('neutral-efficiency', [
      _question('slow', 1, [true], responseMs: 120000),
    ]);
    final neutral = engine.evaluate(result);
    const calibrated = AdaptiveAssessmentEngine(
      policy: AdaptiveAssessmentPolicy(neutralResponseEfficiency: 50),
    );
    final withConfiguredScore = calibrated.evaluate(
      _result('calibrated-efficiency', [
        _question('slow', 1, [true], responseMs: 120000),
      ]),
    );

    expect(neutral.scoreComponents.responseEfficiency, 100);
    expect(neutral.sessionScore, 100);
    expect(withConfiguredScore.scoreComponents.responseEfficiency, 50);
    expect(withConfiguredScore.sessionScore, 95);
  });

  test(
    'first mastery initializes from score; subsequent mastery is weighted',
    () {
      final firstResult = _result('mastery-1', [
        _question('a', 1, [true]),
      ]);
      final first = engine.evaluate(firstResult);
      expect(first.newMastery, 100);

      final second = engine.evaluate(
        _result('mastery-2', [
          _question('b', 1, [false]),
        ]),
        historicalState: first.updatedState.copyWith(mastery: 80),
      );
      expect(second.sessionScore, 20);
      expect(second.newMastery, 62);
      expect(second.newMastery, inInclusiveRange(0, 100));
    },
  );

  test(
    'skill evaluation requires three attempts and reports weak/satisfactory',
    () {
      final insufficient = engine.evaluate(
        _result('skill-1', [
          _question('single', 1, [false]),
        ]),
      );
      expect(insufficient.skillAssessments, isEmpty);
      expect(insufficient.focusSkill, isNull);
      expect(
        insufficient.diagnostics.any(
          (item) => item.contains('Insufficient skill evidence'),
        ),
        isTrue,
      );

      final weak = engine.evaluate(
        _result('skill-weak', [
          _question('weak-a', 1, [false, false, true], skill: 'weak-skill'),
          _question('strong-a', 1, [true, true, true], skill: 'strong-skill'),
        ]),
      );
      expect(
        weak.skillAssessments['weak-skill']!.accuracy,
        closeTo(33.333, 0.001),
      );
      expect(
        weak.skillAssessments['weak-skill']!.status,
        SkillStatus.strongReinforcement,
      );
      expect(
        weak.skillAssessments['strong-skill']!.status,
        SkillStatus.satisfactory,
      );
      expect(weak.focusSkill, 'weak-skill');

      final practice = engine.evaluate(
        _result('skill-practice', [
          _question('practice', 1, [true, true, false], skill: 'practice'),
        ]),
      );
      expect(
        practice.skillAssessments['practice']!.status,
        SkillStatus.additionalPractice,
      );
    },
  );

  test(
    'difficulty increases, decreases, and maintains according to ordered rules',
    () {
      final increase = engine.evaluate(
        _result('increase', [
          _question('medium', 2, [true]),
        ]),
        historicalState: _state(
          difficulty: AdaptiveDifficulty.medium,
          mastery: 80,
          recentScores: [90, 90],
          sessions: 2,
        ),
      );
      expect(increase.nextDifficulty, AdaptiveDifficulty.hard);

      final decrease = engine.evaluate(
        _result('latest-poor', [
          _question('medium', 2, [false]),
        ]),
        historicalState: _state(
          difficulty: AdaptiveDifficulty.hard,
          mastery: 95,
          recentScores: [100, 100],
          sessions: 2,
        ),
      );
      expect(decrease.nextDifficulty, AdaptiveDifficulty.medium);
      expect(
        decrease.diagnostics.any((item) => item.contains('takes precedence')),
        isTrue,
      );

      final maintain = engine.evaluate(
        _result('maintain', [
          _question('medium', 2, [true, false]),
        ]),
        historicalState: _state(
          difficulty: AdaptiveDifficulty.medium,
          mastery: 50,
          recentScores: [70, 70],
          sessions: 2,
        ),
      );
      expect(maintain.nextDifficulty, AdaptiveDifficulty.medium);
    },
  );

  test('difficulty is clamped at Easy and Hard boundaries', () {
    final stayEasy = engine.evaluate(
      _result('easy-boundary', [
        _question('easy', 1, [false]),
      ]),
      historicalState: _state(difficulty: AdaptiveDifficulty.easy),
    );
    final stayHard = engine.evaluate(
      _result('hard-boundary', [
        _question('hard', 3, [true]),
      ]),
      historicalState: _state(
        difficulty: AdaptiveDifficulty.hard,
        mastery: 100,
        recentScores: [100, 100],
      ),
    );

    expect(stayEasy.nextDifficulty, AdaptiveDifficulty.easy);
    expect(stayHard.nextDifficulty, AdaptiveDifficulty.hard);
  });

  test('level completion requires all criteria and medium evidence', () {
    final previous = _state(
      difficulty: AdaptiveDifficulty.medium,
      mastery: 100,
      sessions: 1,
      recentScores: [100],
      skills: {'counting': const SkillPerformance(attempts: 3, correct: 3)},
      mediumSessions: 1,
    );
    final complete = engine.evaluate(
      _result('complete-level', [
        _question('medium-one', 2, [true], skill: 'counting'),
        _question('medium-two', 2, [true], skill: 'counting'),
        _question('medium-three', 2, [true], skill: 'counting'),
      ]),
      historicalState: previous,
    );
    expect(complete.levelComplete, isTrue);
    expect(complete.updatedState.completedLevelIds, contains('level-test'));

    final noMedium = engine.evaluate(
      _result('no-medium', [
        _question('easy-a', 1, [true]),
        _question('easy-b', 1, [true]),
        _question('easy-c', 1, [true]),
      ]),
      historicalState: previous.copyWith(successfulMediumSessionCount: 0),
    );
    expect(noMedium.levelComplete, isFalse);
    expect(
      noMedium.diagnostics.any((item) => item.contains('successful medium')),
      isTrue,
    );
  });

  test('level completion remains false with insufficient evidence', () {
    final decision = engine.evaluate(
      _result('first-session', [
        _question('one', 1, [true]),
      ]),
    );
    expect(decision.levelComplete, isFalse);
    expect(decision.hasSufficientEvidence, isTrue);
    expect(decision.levelCompletionEvidenceSufficient, isFalse);
    expect(
      decision.diagnostics.any(
        (item) => item.contains('two completed sessions'),
      ),
      isTrue,
    );
  });

  test('an evaluated skill below 50 percent blocks level completion', () {
    final previous = _state(
      difficulty: AdaptiveDifficulty.medium,
      mastery: 100,
      sessions: 1,
      recentScores: [100],
      mediumSessions: 1,
      skills: {'weak': const SkillPerformance(attempts: 6, correct: 0)},
    );
    final result = engine.evaluate(
      _result('weak-skill-blocks', [
        _question('medium-one', 2, [true]),
        _question('medium-two', 2, [true]),
        _question('medium-three', 2, [true]),
      ]),
      historicalState: previous,
    );
    expect(result.levelComplete, isFalse);
    expect(
      result.diagnostics.any(
        (item) => item.contains('no evaluated skill below 50%: not met'),
      ),
      isTrue,
    );
  });

  test('trend boundaries and insufficient history are explicit', () {
    expect(engine.trendFor(const []), LearningTrend.notEnoughData);
    LearningTrend trend(double first, double last) => engine.trendFor([
      MasterySnapshot(recordedAt: DateTime.utc(2026, 1, 1), mastery: first),
      MasterySnapshot(recordedAt: DateTime.utc(2026, 1, 2), mastery: last),
    ]);

    expect(trend(50, 55), LearningTrend.improving);
    expect(trend(50, 46), LearningTrend.stable);
    expect(trend(50, 45), LearningTrend.declining);
  });

  test('reprocessing a completed session does not change historical state', () {
    final result = _result('same-session', [
      _question('one', 1, [true]),
    ]);
    final first = engine.evaluate(result);
    final replay = engine.evaluate(result, historicalState: first.updatedState);

    expect(replay.updatedState.completedSessionCount, 1);
    expect(replay.updatedState.mastery, first.updatedState.mastery);
    expect(replay.updatedState.recentSessionScores, hasLength(1));
    expect(replay.diagnostics.first, contains('already processed'));
  });

  test('local adaptive state persists and reloads historical inputs', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalAdaptiveProgressRepository();
    final first = engine.evaluate(
      _result('persisted', [
        _question('one', 1, [true]),
      ]),
    );
    await repository.save(first.updatedState);

    final reopened = LocalAdaptiveProgressRepository();
    final states = await reopened.loadAll();
    expect(states, hasLength(1));
    expect(states.single.completedSessionCount, 1);
    expect(states.single.recentSessionScores, [100]);
    expect(states.single.completedSessionIds, ['persisted']);
    expect(states.single.latestSessionId, 'persisted');
    expect(states.single.latestSessionScore, 100);
  });
}

SessionResult _result(String sessionId, List<QuestionEvidence> evidence) =>
    SessionResult(
      sessionId: sessionId,
      levelId: 'level-test',
      startedAt: DateTime.utc(2026, 1, 1),
      completedAt: DateTime.utc(2026, 1, 1, 0, 1),
      expectedQuestionCount: evidence.length,
      evidence: evidence,
    );

QuestionEvidence _question(
  String id,
  int difficulty,
  List<bool> correctness, {
  String skill = 'skill',
  List<bool>? hints,
  int responseMs = 1000,
}) => QuestionEvidence(
  questionId: id,
  skillTag: skill,
  difficulty: difficulty,
  attempts: [
    for (var index = 0; index < correctness.length; index++)
      AnswerAttempt(
        answer: correctness[index] ? 1 : 0,
        isCorrect: correctness[index],
        responseTime: Duration(milliseconds: responseMs),
        hintUsed: hints != null && index < hints.length ? hints[index] : false,
      ),
  ],
);

AdaptiveProgressState _state({
  AdaptiveDifficulty difficulty = AdaptiveDifficulty.easy,
  double mastery = 0,
  int sessions = 0,
  List<double> recentScores = const [],
  List<MasterySnapshot> snapshots = const [],
  Map<String, SkillPerformance> skills = const {},
  int mediumSessions = 0,
}) => AdaptiveProgressState(
  levelId: 'level-test',
  mastery: mastery,
  currentDifficulty: difficulty,
  completedSessionCount: sessions,
  recentSessionScores: recentScores,
  masterySnapshots: snapshots,
  skillPerformance: skills,
  completedSessionIds: const [],
  successfulMediumSessionCount: mediumSessions,
  completedLevelIds: const [],
);

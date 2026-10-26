import 'session_result.dart';

enum AdaptiveDifficulty {
  easy(1),
  medium(2),
  hard(3);

  final int value;

  const AdaptiveDifficulty(this.value);

  AdaptiveDifficulty get next => switch (this) {
    AdaptiveDifficulty.easy => AdaptiveDifficulty.medium,
    AdaptiveDifficulty.medium => AdaptiveDifficulty.hard,
    AdaptiveDifficulty.hard => AdaptiveDifficulty.hard,
  };

  AdaptiveDifficulty get previous => switch (this) {
    AdaptiveDifficulty.easy => AdaptiveDifficulty.easy,
    AdaptiveDifficulty.medium => AdaptiveDifficulty.easy,
    AdaptiveDifficulty.hard => AdaptiveDifficulty.medium,
  };

  static AdaptiveDifficulty fromValue(int value) => switch (value) {
    1 => AdaptiveDifficulty.easy,
    2 => AdaptiveDifficulty.medium,
    3 => AdaptiveDifficulty.hard,
    _ => throw ArgumentError.value(value, 'value', 'Expected difficulty 1-3'),
  };
}

enum LearningTrend { improving, stable, declining, notEnoughData }

enum SkillStatus { strongReinforcement, additionalPractice, satisfactory }

class ScoreComponents {
  final double? weightedAccuracy;
  final double? hintIndependence;
  final double responseEfficiency;
  final double? sessionScore;

  const ScoreComponents({
    required this.weightedAccuracy,
    required this.hintIndependence,
    required this.responseEfficiency,
    required this.sessionScore,
  });
}

class SkillPerformance {
  final int attempts;
  final int correct;

  const SkillPerformance({required this.attempts, required this.correct});

  double get accuracy => attempts == 0 ? 0 : correct / attempts * 100;

  SkillPerformance add({required int attempts, required int correct}) =>
      SkillPerformance(
        attempts: this.attempts + attempts,
        correct: this.correct + correct,
      );

  Map<String, Object> toJson() => {'attempts': attempts, 'correct': correct};

  factory SkillPerformance.fromJson(Map<String, dynamic> json) =>
      SkillPerformance(
        attempts: json['attempts'] as int,
        correct: json['correct'] as int,
      );
}

class MasterySnapshot {
  final DateTime recordedAt;
  final double mastery;

  const MasterySnapshot({required this.recordedAt, required this.mastery});

  Map<String, Object?> toJson() => {
    'recordedAt': recordedAt.toIso8601String(),
    'mastery': mastery,
  };

  factory MasterySnapshot.fromJson(Map<String, dynamic> json) =>
      MasterySnapshot(
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        mastery: (json['mastery'] as num).toDouble(),
      );
}

class AdaptiveProgressState {
  static const empty = AdaptiveProgressState(
    levelId: '',
    mastery: 0,
    currentDifficulty: AdaptiveDifficulty.easy,
    completedSessionCount: 0,
    recentSessionScores: [],
    masterySnapshots: [],
    skillPerformance: {},
    completedSessionIds: [],
    successfulMediumSessionCount: 0,
    completedLevelIds: [],
    latestSessionId: null,
    latestSessionScore: null,
    latestFocusSkill: null,
    latestLevelComplete: false,
    latestLevelCompletionEvidenceSufficient: false,
    latestTrend: LearningTrend.notEnoughData,
    latestDiagnostics: [],
    recentQuestionIds: [],
  );

  final String levelId;
  final double mastery;
  final AdaptiveDifficulty currentDifficulty;
  final int completedSessionCount;
  final List<double> recentSessionScores;
  final List<MasterySnapshot> masterySnapshots;
  final Map<String, SkillPerformance> skillPerformance;
  final List<String> completedSessionIds;
  final int successfulMediumSessionCount;
  final List<String> completedLevelIds;
  final String? latestSessionId;
  final double? latestSessionScore;
  final String? latestFocusSkill;
  final bool latestLevelComplete;
  final bool latestLevelCompletionEvidenceSufficient;
  final LearningTrend latestTrend;
  final List<String> latestDiagnostics;
  final List<String> recentQuestionIds;

  const AdaptiveProgressState({
    required this.levelId,
    required this.mastery,
    required this.currentDifficulty,
    required this.completedSessionCount,
    required this.recentSessionScores,
    required this.masterySnapshots,
    required this.skillPerformance,
    required this.completedSessionIds,
    required this.successfulMediumSessionCount,
    required this.completedLevelIds,
    this.latestSessionId,
    this.latestSessionScore,
    this.latestFocusSkill,
    this.latestLevelComplete = false,
    this.latestLevelCompletionEvidenceSufficient = false,
    this.latestTrend = LearningTrend.notEnoughData,
    this.latestDiagnostics = const [],
    this.recentQuestionIds = const [],
  });

  bool hasProcessed(String sessionId) =>
      completedSessionIds.contains(sessionId);

  Map<String, Object?> toJson() => {
    'levelId': levelId,
    'mastery': mastery,
    'currentDifficulty': currentDifficulty.value,
    'completedSessionCount': completedSessionCount,
    'recentSessionScores': recentSessionScores,
    'masterySnapshots': masterySnapshots.map((item) => item.toJson()).toList(),
    'skillPerformance': skillPerformance.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'completedSessionIds': completedSessionIds,
    'successfulMediumSessionCount': successfulMediumSessionCount,
    'completedLevelIds': completedLevelIds,
    'latestSessionId': latestSessionId,
    'latestSessionScore': latestSessionScore,
    'latestFocusSkill': latestFocusSkill,
    'latestLevelComplete': latestLevelComplete,
    'latestLevelCompletionEvidenceSufficient':
        latestLevelCompletionEvidenceSufficient,
    'latestTrend': latestTrend.name,
    'latestDiagnostics': latestDiagnostics,
    'recentQuestionIds': recentQuestionIds,
  };

  factory AdaptiveProgressState.fromJson(
    Map<String, dynamic> json,
  ) => AdaptiveProgressState(
    levelId: json['levelId'] as String,
    mastery: (json['mastery'] as num).toDouble(),
    currentDifficulty: AdaptiveDifficulty.fromValue(
      json['currentDifficulty'] as int,
    ),
    completedSessionCount: json['completedSessionCount'] as int,
    recentSessionScores: (json['recentSessionScores'] as List<dynamic>)
        .map((item) => (item as num).toDouble())
        .toList(),
    masterySnapshots: (json['masterySnapshots'] as List<dynamic>)
        .map(
          (item) =>
              MasterySnapshot.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    skillPerformance: (json['skillPerformance'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        SkillPerformance.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    ),
    completedSessionIds: (json['completedSessionIds'] as List<dynamic>)
        .cast<String>(),
    successfulMediumSessionCount: json['successfulMediumSessionCount'] as int,
    completedLevelIds: (json['completedLevelIds'] as List<dynamic>)
        .cast<String>(),
    latestSessionId: json['latestSessionId'] as String?,
    latestSessionScore: (json['latestSessionScore'] as num?)?.toDouble(),
    latestFocusSkill: json['latestFocusSkill'] as String?,
    latestLevelComplete: json['latestLevelComplete'] as bool? ?? false,
    latestLevelCompletionEvidenceSufficient:
        json['latestLevelCompletionEvidenceSufficient'] as bool? ?? false,
    latestTrend: LearningTrend.values.firstWhere(
      (trend) => trend.name == json['latestTrend'],
      orElse: () => LearningTrend.notEnoughData,
    ),
    latestDiagnostics:
        (json['latestDiagnostics'] as List<dynamic>?)?.cast<String>() ??
        const [],
    recentQuestionIds:
        (json['recentQuestionIds'] as List<dynamic>?)?.cast<String>() ??
        const [],
  );
}

class SkillAssessment {
  final String skillTag;
  final int attempts;
  final int correct;
  final double accuracy;
  final SkillStatus status;

  const SkillAssessment({
    required this.skillTag,
    required this.attempts,
    required this.correct,
    required this.accuracy,
    required this.status,
  });
}

class AdaptiveAssessmentDecision {
  final String sessionId;
  final double? sessionScore;
  final ScoreComponents scoreComponents;
  final double newMastery;
  final AdaptiveDifficulty nextDifficulty;
  final String? focusSkill;
  final bool levelComplete;
  final bool hasSufficientEvidence;
  final bool levelCompletionEvidenceSufficient;
  final LearningTrend trend;
  final Map<String, SkillAssessment> skillAssessments;
  final List<String> diagnostics;
  final AdaptiveProgressState updatedState;

  const AdaptiveAssessmentDecision({
    required this.sessionId,
    required this.sessionScore,
    required this.scoreComponents,
    required this.newMastery,
    required this.nextDifficulty,
    required this.focusSkill,
    required this.levelComplete,
    required this.hasSufficientEvidence,
    required this.levelCompletionEvidenceSufficient,
    required this.trend,
    required this.skillAssessments,
    required this.diagnostics,
    required this.updatedState,
  });
}

class AdaptiveAssessmentPolicy {
  final double neutralResponseEfficiency;
  final int recentScoreWindow;
  final int masteryTrendWindow;
  final int minimumSkillAttempts;

  const AdaptiveAssessmentPolicy({
    this.neutralResponseEfficiency = 100,
    this.recentScoreWindow = 3,
    this.masteryTrendWindow = 2,
    this.minimumSkillAttempts = 3,
  }) : assert(
         neutralResponseEfficiency >= 0 && neutralResponseEfficiency <= 100,
       ),
       assert(recentScoreWindow > 0),
       assert(masteryTrendWindow >= 2),
       assert(minimumSkillAttempts > 0);
}

class AdaptiveAssessmentEngine {
  static const difficultyWeights = {1: 1.0, 2: 1.2, 3: 1.4};

  final AdaptiveAssessmentPolicy policy;

  const AdaptiveAssessmentEngine({
    this.policy = const AdaptiveAssessmentPolicy(),
  });

  AdaptiveAssessmentDecision evaluate(
    SessionResult result, {
    AdaptiveProgressState historicalState = AdaptiveProgressState.empty,
  }) {
    final state = historicalState.levelId == result.levelId
        ? historicalState
        : AdaptiveProgressState(
            levelId: result.levelId,
            mastery: 0,
            currentDifficulty: AdaptiveDifficulty.easy,
            completedSessionCount: 0,
            recentSessionScores: const [],
            masterySnapshots: const [],
            skillPerformance: const {},
            completedSessionIds: const [],
            successfulMediumSessionCount: 0,
            completedLevelIds: historicalState.completedLevelIds,
          );
    if (state.hasProcessed(result.sessionId)) {
      return _duplicateDecision(result, state);
    }

    final attempts = [
      for (final question in result.evidence) ...question.attempts,
    ];
    final completeEvidence =
        result.expectedQuestionCount != null &&
        result.evidence.length == result.expectedQuestionCount &&
        result.evidence.isNotEmpty &&
        result.evidence.every((question) => question.attempts.isNotEmpty);
    final scoreComponents = _score(result);
    final sessionScore = scoreComponents.sessionScore;
    final diagnostics = <String>[
      if (!completeEvidence)
        'Session evidence is incomplete; mastery, skill history and difficulty are unchanged.',
      if (result.expectedQuestionCount == null)
        'Expected question count is missing; completeness cannot be verified for this legacy session result.',
      if (result.expectedQuestionCount != null &&
          result.evidence.length != result.expectedQuestionCount)
        'Expected ${result.expectedQuestionCount} question records, received ${result.evidence.length}.',
      if (attempts.isEmpty)
        'No answer attempts are available, so a session score cannot be calculated.',
      'Response efficiency uses the configured neutral value '
          '${policy.neutralResponseEfficiency.toStringAsFixed(0)} because no validated speed target exists.',
    ];
    if (!completeEvidence || sessionScore == null) {
      final incompleteDiagnostics = [
        ...diagnostics,
        if (state.skillPerformance.values.every(
          (skill) => skill.attempts < policy.minimumSkillAttempts,
        ))
          'Insufficient skill evidence: no skill has at least '
              '${policy.minimumSkillAttempts} relevant attempts.',
      ];
      final focusSkill = _focusSkill(state.skillPerformance);
      final trend = trendFor(state.masterySnapshots);
      return AdaptiveAssessmentDecision(
        sessionId: result.sessionId,
        sessionScore: sessionScore,
        scoreComponents: scoreComponents,
        newMastery: state.mastery,
        nextDifficulty: state.currentDifficulty,
        focusSkill: focusSkill,
        levelComplete: false,
        hasSufficientEvidence: false,
        levelCompletionEvidenceSufficient: false,
        trend: trend,
        skillAssessments: _assessSkills(state.skillPerformance),
        diagnostics: List.unmodifiable(incompleteDiagnostics),
        updatedState: state.copyWith(
          completedSessionIds: [...state.completedSessionIds, result.sessionId],
          latestSessionId: result.sessionId,
          latestSessionScore: sessionScore,
          latestFocusSkill: focusSkill,
          latestLevelComplete: false,
          latestLevelCompletionEvidenceSufficient: false,
          latestTrend: trend,
          latestDiagnostics: incompleteDiagnostics,
          clearLatestSummary: true,
        ),
      );
    }

    final newMastery = state.completedSessionCount == 0
        ? sessionScore
        : _clamp(0.70 * state.mastery + 0.30 * sessionScore);
    final skillPerformance = _updateSkillPerformance(
      state.skillPerformance,
      result,
    );
    final skillAssessments = _assessSkills(skillPerformance);
    if (skillAssessments.isEmpty) {
      diagnostics.add(
        'Insufficient skill evidence: no skill has at least '
        '${policy.minimumSkillAttempts} relevant attempts.',
      );
    }
    final focusSkill = _focusSkill(skillPerformance);
    final recentScores = [
      ...state.recentSessionScores,
      sessionScore,
    ].takeLast(policy.recentScoreWindow).toList();
    final nextDifficulty = _nextDifficulty(
      current: state.currentDifficulty,
      recentScores: recentScores,
      latestScore: sessionScore,
      mastery: newMastery,
      diagnostics: diagnostics,
    );
    final successfulMedium = _isSuccessfulMediumSession(result, sessionScore);
    final snapshots = [
      ...state.masterySnapshots,
      MasterySnapshot(recordedAt: result.completedAt, mastery: newMastery),
    ].takeLast(10).toList();
    final completedSessionIds = [
      ...state.completedSessionIds,
      result.sessionId,
    ];
    final eligibleSkillBelow50 = skillAssessments.values.any(
      (skill) => skill.accuracy < 50,
    );
    final completionCriteria = {
      'at least two completed sessions': state.completedSessionCount + 1 >= 2,
      'mastery at least 75': newMastery >= 75,
      'successful medium session':
          successfulMedium || state.successfulMediumSessionCount > 0,
      'at least one sufficiently observed skill': skillAssessments.isNotEmpty,
      'no evaluated skill below 50%': !eligibleSkillBelow50,
    };
    final wasAlreadyComplete = state.completedLevelIds.contains(result.levelId);
    final levelComplete =
        wasAlreadyComplete || completionCriteria.values.every((value) => value);
    if (wasAlreadyComplete) {
      diagnostics.add(
        'Level was previously marked complete; completion is retained.',
      );
    }
    for (final entry in completionCriteria.entries) {
      diagnostics.add('${entry.key}: ${entry.value ? 'met' : 'not met'}.');
    }

    final recentQuestionIds = [
      ...state.recentQuestionIds,
      ...result.evidence.map((item) => item.questionId),
    ];
    final updatedState = state.copyWith(
      mastery: newMastery,
      currentDifficulty: nextDifficulty,
      completedSessionCount: state.completedSessionCount + 1,
      recentSessionScores: recentScores,
      masterySnapshots: snapshots,
      skillPerformance: skillPerformance,
      completedSessionIds: completedSessionIds,
      successfulMediumSessionCount:
          state.successfulMediumSessionCount + (successfulMedium ? 1 : 0),
      completedLevelIds: levelComplete
          ? {...state.completedLevelIds, result.levelId}.toList()
          : state.completedLevelIds,
      latestSessionId: result.sessionId,
      latestSessionScore: sessionScore,
      latestFocusSkill: focusSkill,
      latestLevelComplete: levelComplete,
      latestLevelCompletionEvidenceSufficient: skillAssessments.isNotEmpty,
      latestTrend: trendFor(snapshots),
      latestDiagnostics: diagnostics,
      recentQuestionIds: recentQuestionIds
          .skip(
            recentQuestionIds.length > 30 ? recentQuestionIds.length - 30 : 0,
          )
          .toList(),
    );
    return AdaptiveAssessmentDecision(
      sessionId: result.sessionId,
      sessionScore: sessionScore,
      scoreComponents: scoreComponents,
      newMastery: newMastery,
      nextDifficulty: nextDifficulty,
      focusSkill: focusSkill,
      levelComplete: levelComplete,
      hasSufficientEvidence: true,
      levelCompletionEvidenceSufficient: skillAssessments.isNotEmpty,
      trend: trendFor(snapshots),
      skillAssessments: Map.unmodifiable(skillAssessments),
      diagnostics: List.unmodifiable(diagnostics),
      updatedState: updatedState,
    );
  }

  ScoreComponents _score(SessionResult result) {
    var weightedCorrect = 0.0;
    var totalWeight = 0.0;
    var independentAttempts = 0;
    var attemptCount = 0;
    for (final question in result.evidence) {
      final weight = difficultyWeights[question.difficulty];
      if (weight == null) {
        throw ArgumentError(
          'Unsupported question difficulty ${question.difficulty} '
          'in ${question.questionId}.',
        );
      }
      for (final attempt in question.attempts) {
        attemptCount++;
        totalWeight += weight;
        if (attempt.isCorrect) weightedCorrect += weight;
        if (!attempt.hintUsed) independentAttempts++;
      }
    }
    final weightedAccuracy = totalWeight == 0
        ? null
        : weightedCorrect / totalWeight * 100;
    final hintIndependence = attemptCount == 0
        ? null
        : independentAttempts / attemptCount * 100;
    final responseEfficiency = policy.neutralResponseEfficiency;
    final sessionScore = weightedAccuracy == null || hintIndependence == null
        ? null
        : _clamp(
            0.80 * weightedAccuracy +
                0.10 * hintIndependence +
                0.10 * responseEfficiency,
          );
    return ScoreComponents(
      weightedAccuracy: weightedAccuracy,
      hintIndependence: hintIndependence,
      responseEfficiency: responseEfficiency,
      sessionScore: sessionScore,
    );
  }

  AdaptiveDifficulty _nextDifficulty({
    required AdaptiveDifficulty current,
    required List<double> recentScores,
    required double latestScore,
    required double mastery,
    required List<String> diagnostics,
  }) {
    final recentAverage =
        recentScores.reduce((a, b) => a + b) / recentScores.length;
    if (latestScore < 50 || recentAverage < 60) {
      diagnostics.add(
        'Difficulty decreased because the latest score is below 50 or the recent average is below 60; decrease takes precedence.',
      );
      return current.previous;
    }
    if (recentAverage >= 80 && mastery >= 75) {
      diagnostics.add(
        'Difficulty increased because recent average is at least 80 and mastery is at least 75.',
      );
      return current.next;
    }
    diagnostics.add(
      'Difficulty maintained: increase thresholds are unmet and no decrease rule applies.',
    );
    return current;
  }

  Map<String, SkillPerformance> _updateSkillPerformance(
    Map<String, SkillPerformance> previous,
    SessionResult result,
  ) {
    final updated = Map<String, SkillPerformance>.of(previous);
    for (final question in result.evidence) {
      final skill =
          updated[question.skillTag] ??
          const SkillPerformance(attempts: 0, correct: 0);
      updated[question.skillTag] = skill.add(
        attempts: question.attempts.length,
        correct: question.attempts.where((attempt) => attempt.isCorrect).length,
      );
    }
    return Map.unmodifiable(updated);
  }

  Map<String, SkillAssessment> _assessSkills(
    Map<String, SkillPerformance> performance,
  ) {
    return {
      for (final entry in performance.entries)
        if (entry.value.attempts >= policy.minimumSkillAttempts)
          entry.key: SkillAssessment(
            skillTag: entry.key,
            attempts: entry.value.attempts,
            correct: entry.value.correct,
            accuracy: entry.value.accuracy,
            status: entry.value.accuracy < 60
                ? SkillStatus.strongReinforcement
                : entry.value.accuracy < 75
                ? SkillStatus.additionalPractice
                : SkillStatus.satisfactory,
          ),
    };
  }

  String? _focusSkill(Map<String, SkillPerformance> performance) {
    final eligible =
        performance.entries
            .where(
              (entry) => entry.value.attempts >= policy.minimumSkillAttempts,
            )
            .toList()
          ..sort((a, b) {
            final accuracy = a.value.accuracy.compareTo(b.value.accuracy);
            return accuracy != 0 ? accuracy : a.key.compareTo(b.key);
          });
    return eligible.isEmpty ? null : eligible.first.key;
  }

  bool _isSuccessfulMediumSession(SessionResult result, double score) =>
      score >= 75 &&
      result.evidence.any(
        (item) =>
            item.difficulty == AdaptiveDifficulty.medium.value &&
            item.attempts.any((attempt) => attempt.isCorrect),
      );

  LearningTrend trendFor(List<MasterySnapshot> snapshots) {
    if (snapshots.length < policy.masteryTrendWindow) {
      return LearningTrend.notEnoughData;
    }
    final window = snapshots.takeLast(policy.masteryTrendWindow);
    final change = window.last.mastery - window.first.mastery;
    if (change >= 5) return LearningTrend.improving;
    if (change <= -5) return LearningTrend.declining;
    return LearningTrend.stable;
  }

  AdaptiveAssessmentDecision _duplicateDecision(
    SessionResult result,
    AdaptiveProgressState state,
  ) => AdaptiveAssessmentDecision(
    sessionId: result.sessionId,
    sessionScore: state.latestSessionId == result.sessionId
        ? state.latestSessionScore
        : null,
    scoreComponents: ScoreComponents(
      weightedAccuracy: null,
      hintIndependence: null,
      responseEfficiency: policy.neutralResponseEfficiency,
      sessionScore: null,
    ),
    newMastery: state.mastery,
    nextDifficulty: state.currentDifficulty,
    focusSkill: _focusSkill(state.skillPerformance),
    levelComplete: state.latestSessionId == result.sessionId
        ? state.latestLevelComplete
        : state.completedLevelIds.contains(result.levelId),
    hasSufficientEvidence: false,
    levelCompletionEvidenceSufficient: _assessSkills(
      state.skillPerformance,
    ).isNotEmpty,
    trend: state.latestSessionId == result.sessionId
        ? state.latestTrend
        : trendFor(state.masterySnapshots),
    skillAssessments: Map.unmodifiable(_assessSkills(state.skillPerformance)),
    diagnostics: [
      'Session was already processed; historical state unchanged.',
      ...state.latestDiagnostics,
    ],
    updatedState: state,
  );
}

extension _TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final values = toList();
    return values.skip(values.length > count ? values.length - count : 0);
  }
}

double _clamp(double value) => value.clamp(0, 100).toDouble();

extension AdaptiveProgressCopy on AdaptiveProgressState {
  AdaptiveProgressState copyWith({
    double? mastery,
    AdaptiveDifficulty? currentDifficulty,
    int? completedSessionCount,
    List<double>? recentSessionScores,
    List<MasterySnapshot>? masterySnapshots,
    Map<String, SkillPerformance>? skillPerformance,
    List<String>? completedSessionIds,
    int? successfulMediumSessionCount,
    List<String>? completedLevelIds,
    String? latestSessionId,
    double? latestSessionScore,
    String? latestFocusSkill,
    bool? latestLevelComplete,
    bool? latestLevelCompletionEvidenceSufficient,
    LearningTrend? latestTrend,
    List<String>? latestDiagnostics,
    List<String>? recentQuestionIds,
    bool clearLatestSummary = false,
  }) => AdaptiveProgressState(
    levelId: levelId,
    mastery: mastery ?? this.mastery,
    currentDifficulty: currentDifficulty ?? this.currentDifficulty,
    completedSessionCount: completedSessionCount ?? this.completedSessionCount,
    recentSessionScores: recentSessionScores ?? this.recentSessionScores,
    masterySnapshots: masterySnapshots ?? this.masterySnapshots,
    skillPerformance: skillPerformance ?? this.skillPerformance,
    completedSessionIds: completedSessionIds ?? this.completedSessionIds,
    successfulMediumSessionCount:
        successfulMediumSessionCount ?? this.successfulMediumSessionCount,
    completedLevelIds: completedLevelIds ?? this.completedLevelIds,
    latestSessionId: latestSessionId ?? this.latestSessionId,
    latestSessionScore: clearLatestSummary
        ? latestSessionScore
        : latestSessionScore ?? this.latestSessionScore,
    latestFocusSkill: clearLatestSummary
        ? latestFocusSkill
        : latestFocusSkill ?? this.latestFocusSkill,
    latestLevelComplete: latestLevelComplete ?? this.latestLevelComplete,
    latestLevelCompletionEvidenceSufficient:
        latestLevelCompletionEvidenceSufficient ??
        this.latestLevelCompletionEvidenceSufficient,
    latestTrend: latestTrend ?? this.latestTrend,
    latestDiagnostics: latestDiagnostics ?? this.latestDiagnostics,
    recentQuestionIds: recentQuestionIds ?? this.recentQuestionIds,
  );
}

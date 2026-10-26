import 'dart:math';

import '../domain/activity_content.dart';
import '../domain/adaptive_assessment.dart';
import '../domain/level_definition.dart';
import '../domain/math_question.dart';

class SessionPlanningException implements Exception {
  final String message;

  const SessionPlanningException(this.message);

  @override
  String toString() => message;
}

class AdaptiveSessionPlan {
  final List<MathQuestion> questions;
  final int plannedDifficulty;
  final String? targetSkill;
  final String explanation;
  final List<String> fallbacks;

  const AdaptiveSessionPlan({
    required this.questions,
    required this.plannedDifficulty,
    required this.targetSkill,
    required this.explanation,
    required this.fallbacks,
  });

  List<String> get selectedQuestionIds =>
      List.unmodifiable(questions.map((question) => question.id));

  bool get usedFallback => fallbacks.isNotEmpty;
}

class AdaptiveSessionPlanner {
  const AdaptiveSessionPlanner();

  AdaptiveSessionPlan plan({
    required LevelDefinition level,
    required List<MathQuestion> questionBank,
    required double previousMastery,
    required AdaptiveDifficulty recommendedDifficulty,
    required String? focusSkill,
    required List<String> recentQuestionIds,
    int desiredLength = 5,
    int randomSeed = 0,
  }) {
    if (desiredLength < 1) {
      throw ArgumentError.value(
        desiredLength,
        'desiredLength',
        'Must be positive.',
      );
    }

    final eligible = questionBank
        .where(
          (question) =>
              question.levelId == level.id &&
              level.availableActivityTypes.contains(question.activityType),
        )
        .toList();
    if (eligible.length < desiredLength) {
      throw SessionPlanningException(
        'Level ${level.id} has ${eligible.length} valid eligible questions; '
        '$desiredLength are required.',
      );
    }
    final ids = eligible.map((question) => question.id).toSet();
    if (ids.length != eligible.length) {
      throw SessionPlanningException(
        'Level ${level.id} contains duplicate question IDs.',
      );
    }
    for (final question in eligible) {
      if (question.difficulty < 1 || question.difficulty > 3) {
        throw SessionPlanningException(
          'Question ${question.id} has unsupported difficulty '
          '${question.difficulty}.',
        );
      }
      try {
        ActivityContent.fromQuestion(question);
      } on FormatException catch (error) {
        throw SessionPlanningException(
          'Question ${question.id} is invalid: ${error.message}',
        );
      }
    }

    final random = Random(randomSeed);
    final recentIds = recentQuestionIds.toSet();
    final unseen = eligible
        .where((question) => !recentIds.contains(question.id))
        .toList();
    final selectionPool = unseen.length >= desiredLength ? unseen : eligible;
    final availableFocus = focusSkill == null
        ? <MathQuestion>[]
        : selectionPool
              .where(
                (question) =>
                    question.skillTag == focusSkill &&
                    question.difficulty == recommendedDifficulty.value,
              )
              .toList();
    final otherSkills = eligible.any(
      (question) => question.skillTag != focusSkill,
    );
    final focusTarget = focusSkill == null || availableFocus.isEmpty
        ? 0
        : min(
            availableFocus.length,
            min(desiredLength - (otherSkills ? 1 : 0), 3),
          );
    final fallbacks = <String>[];
    final selected = <MathQuestion>[];

    for (var index = 0; index < focusTarget; index++) {
      final question = _choose(
        selectionPool
            .where(
              (candidate) =>
                  candidate.skillTag == focusSkill &&
                  !selected.contains(candidate),
            )
            .toList(),
        recommendedDifficulty.value,
        recentIds,
        random,
      );
      selected.add(question);
    }
    if (focusSkill != null && focusTarget < min(3, desiredLength)) {
      fallbacks.add(
        'Fewer than three focus-skill questions at the recommended difficulty '
        'were available.',
      );
    }

    while (selected.length < desiredLength) {
      var candidates = selectionPool
          .where((question) => !selected.contains(question))
          .toList();
      final nearestBand = candidates
          .map(
            (question) =>
                (question.difficulty - recommendedDifficulty.value).abs(),
          )
          .reduce(min);
      candidates = candidates
          .where(
            (question) =>
                (question.difficulty - recommendedDifficulty.value).abs() ==
                nearestBand,
          )
          .toList();
      final unselectedOthers = candidates
          .where((question) => question.skillTag != focusSkill)
          .toList();
      if (unselectedOthers.isNotEmpty) {
        final minimumCount = unselectedOthers
            .map(
              (question) => selected
                  .where((item) => item.skillTag == question.skillTag)
                  .length,
            )
            .reduce(min);
        candidates = unselectedOthers
            .where(
              (question) =>
                  selected
                      .where((item) => item.skillTag == question.skillTag)
                      .length ==
                  minimumCount,
            )
            .toList();
      }
      selected.add(
        _choose(candidates, recommendedDifficulty.value, recentIds, random),
      );
    }

    final selectedAtRecommendedDifficulty = selected
        .where((question) => question.difficulty == recommendedDifficulty.value)
        .length;
    if (selectedAtRecommendedDifficulty < desiredLength) {
      fallbacks.add(
        'Used adjacent difficulty bands because only '
        '$selectedAtRecommendedDifficulty of $desiredLength selected questions '
        'matched the recommended difficulty.',
      );
    }
    final nonRecentCount = unseen.length;
    if (nonRecentCount < desiredLength &&
        selected.any((question) => recentIds.contains(question.id))) {
      fallbacks.add(
        'Reused older questions because fewer than $desiredLength unseen '
        'questions were available.',
      );
    }
    if (focusSkill != null && availableFocus.isEmpty) {
      fallbacks.add(
        'The requested focus skill "$focusSkill" was not present in this bank.',
      );
    }

    final difficultyCounts = <int, int>{};
    final skillCounts = <String, int>{};
    for (final question in selected) {
      difficultyCounts.update(
        question.difficulty,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      skillCounts.update(
        question.skillTag,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final plannedDifficulty = difficultyCounts.keys.reduce((left, right) {
      final countOrder = difficultyCounts[left]!.compareTo(
        difficultyCounts[right]!,
      );
      if (countOrder != 0) return countOrder > 0 ? left : right;
      final leftDistance = (left - recommendedDifficulty.value).abs();
      final rightDistance = (right - recommendedDifficulty.value).abs();
      return leftDistance <= rightDistance ? left : right;
    });
    final targetSkill =
        focusSkill != null && skillCounts.containsKey(focusSkill)
        ? focusSkill
        : skillCounts.keys.reduce(
            (left, right) =>
                skillCounts[left]! >= skillCounts[right]! ? left : right,
          );

    return AdaptiveSessionPlan(
      questions: List.unmodifiable(selected),
      plannedDifficulty: plannedDifficulty,
      targetSkill: targetSkill,
      explanation:
          'Selected ${selected.length} questions for ${level.learningTopic}; '
          '${difficultyCounts[recommendedDifficulty.value] ?? 0} match the '
          '${recommendedDifficulty.name} recommendation. '
          'Focus: $targetSkill. Previous mastery: '
          '${previousMastery.toStringAsFixed(1)}%. '
          '${fallbacks.isEmpty ? 'No fallback was needed.' : fallbacks.join(' ')}',
      fallbacks: List.unmodifiable(fallbacks),
    );
  }

  MathQuestion _choose(
    List<MathQuestion> candidates,
    int desiredDifficulty,
    Set<String> recentIds,
    Random random,
  ) {
    final nearestDifficulty = candidates
        .map((question) => (question.difficulty - desiredDifficulty).abs())
        .reduce(min);
    final nearest = candidates
        .where(
          (question) =>
              (question.difficulty - desiredDifficulty).abs() ==
              nearestDifficulty,
        )
        .toList();
    final notRecent = nearest
        .where((question) => !recentIds.contains(question.id))
        .toList();
    final pool = notRecent.isNotEmpty ? notRecent : nearest;
    return pool[random.nextInt(pool.length)];
  }
}

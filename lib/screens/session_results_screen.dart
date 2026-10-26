import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../content/level_catalog.dart';
import '../domain/adaptive_assessment.dart';
import '../domain/session_result.dart';
import '../progress/session_history_controller.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class SessionResultsScreen extends StatelessWidget {
  const SessionResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    final history = context.watch<SessionHistoryController>();
    final result = history.latestResult;
    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      body: ResponsiveScreen(
        squarishMainArea: Center(
          child: SingleChildScrollView(
            child: history.isLoading
                ? const CircularProgressIndicator()
                : history.errorMessage != null
                ? Text(history.errorMessage!, textAlign: TextAlign.center)
                : result == null
                ? const Text('No completed sessions yet.')
                : _ResultSummary(
                    result: result,
                    progressState: history.learningStates
                        .where((state) => state.levelId == result.levelId)
                        .firstOrNull,
                  ),
          ),
        ),
        rectangularMenuArea: MyButton(
          onPressed: () => context.go('/'),
          child: const Text('Continue'),
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final SessionResult result;
  final AdaptiveProgressState? progressState;

  const _ResultSummary({required this.result, required this.progressState});

  @override
  Widget build(BuildContext context) {
    final level = LevelCatalog.byId(result.levelId);
    final currentAssessment = progressState?.latestSessionId == result.sessionId
        ? progressState
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Session complete!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          '${level?.learningTopic ?? 'Math'} • ${result.correctCount} of '
          '${result.totalQuestions} correct',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
        Text(
          'Attempts recorded: ${result.evidence.fold<int>(0, (total, item) => total + item.attempts.length)}',
          style: const TextStyle(fontSize: 18),
        ),
        if (currentAssessment != null) ...[
          Text(
            'Session score: ${currentAssessment.latestSessionScore?.toStringAsFixed(0) ?? 'Not available'}%',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Mastery: ${currentAssessment.mastery.toStringAsFixed(0)}% '
            '• Recommended: ${currentAssessment.currentDifficulty.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Focus skill: ${currentAssessment.latestFocusSkill ?? 'Not enough evidence'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Level completion: ${currentAssessment.latestLevelComplete ? 'eligible' : 'not yet eligible'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Skill evidence: ${currentAssessment.latestLevelCompletionEvidenceSufficient ? 'sufficient' : 'insufficient'} for completion',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Trend: ${_trendLabel(currentAssessment.latestTrend)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (currentAssessment.latestDiagnostics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                currentAssessment.latestDiagnostics.join('\n'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }

  String _trendLabel(LearningTrend trend) => switch (trend) {
    LearningTrend.improving => 'Improving',
    LearningTrend.stable => 'Stable',
    LearningTrend.declining => 'Declining',
    LearningTrend.notEnoughData => 'Not enough data',
  };
}

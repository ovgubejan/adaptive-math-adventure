import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../content/question_repository.dart';
import '../content/level_catalog.dart';
import '../domain/adaptive_assessment.dart';
import '../persistence/adaptive_progress_repository.dart';
import '../mechanics/activity_renderer.dart';
import '../persistence/session_result_persistence.dart';
import '../presentation/counting_theme.dart';
import '../presentation/mascot/mascot_controller.dart';
import '../presentation/mascot/mascot_session_event_bridge.dart';
import '../presentation/mascot/mascot_widget.dart';
import '../progress/session_history_controller.dart';
import '../session/session_controller.dart';
import '../session/adaptive_session_planner.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlaySessionScreen extends StatefulWidget {
  final String levelId;
  final bool demoMode;

  const PlaySessionScreen({
    required this.levelId,
    this.demoMode = false,
    super.key,
  });

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  late final SessionController _session;
  late final MascotController _mascot;
  late final MascotSessionEventBridge _mascotEventBridge;
  String? _planningError;
  CountingTheme _theme = CountingTheme.themes.first;

  @override
  void initState() {
    super.initState();
    _session = SessionController(
      questionRepository: QuestionRepository(),
      persistence: context.read<SessionResultPersistence>(),
      adaptiveProgressRepository: context.read<AdaptiveProgressRepository>(),
    );
    _mascot = MascotController();
    _mascotEventBridge = MascotSessionEventBridge(_session, _mascot)..attach();
    unawaited(
      widget.demoMode ? _session.startDemoSession() : _startPlannedSession(),
    );
  }

  Future<void> _startPlannedSession() async {
    final level = LevelCatalog.byId(widget.levelId);
    if (level == null || !LevelCatalog.canLaunch(widget.levelId)) {
      await _session.startSession(widget.levelId);
      return;
    }
    try {
      final progressRepository = context.read<AdaptiveProgressRepository>();
      final states = await progressRepository.loadAll();
      final matchingStates = states.where((item) => item.levelId == level.id);
      final state = matchingStates.isEmpty ? null : matchingStates.first;
      final history = state ?? AdaptiveProgressState.empty;
      final recommendedDifficulty = history.completedSessionCount == 0
          ? AdaptiveDifficulty.easy
          : history.currentDifficulty;
      final plan = const AdaptiveSessionPlanner().plan(
        level: level,
        questionBank: QuestionRepository().questionsFor(level),
        previousMastery: history.mastery,
        recommendedDifficulty: recommendedDifficulty,
        focusSkill: history.latestFocusSkill,
        recentQuestionIds: history.recentQuestionIds,
        desiredLength: 5,
        randomSeed: DateTime.now().microsecondsSinceEpoch,
      );
      await _session.startPlannedSession(level.id, plan.questions);
    } catch (error) {
      if (!mounted) return;
      setState(() => _planningError = 'Could not prepare this session: $error');
    }
  }

  @override
  void dispose() {
    _mascotEventBridge.dispose();
    _mascot.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    return ListenableBuilder(
      listenable: _session,
      builder: (context, child) {
        final question = _session.currentQuestion;
        return Scaffold(
          backgroundColor: palette.backgroundPlaySession,
          body: ResponsiveScreen(
            topMessageArea: Text(
              _session.status == SessionStatus.active
                  ? 'Question ${_session.currentIndex + 1} of ${_session.questionCount}'
                  : widget.demoMode
                  ? 'Activity mechanics demo'
                  : 'Math adventure',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            squarishMainArea: Center(
              child: _session.status == SessionStatus.active && question != null
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListenableBuilder(
                            listenable: _mascot,
                            builder: (context, child) => MascotWidget(
                              state: _mascot.state,
                              celebrationId: _mascot.celebrationId,
                              size: 112,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ActivityRenderer(
                            question: question,
                            theme: _theme,
                            answerLocked: _session.canAdvance,
                            onAnswer: _session.submitAnswer,
                          ),
                          if (_session.canAdvance) ...[
                            const SizedBox(height: 12),
                            Text(
                              _session.lastAnswerCorrect!
                                  ? 'That is right!'
                                  : 'Good try! Let’s keep going.',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_session.persistenceError != null)
                              Text(
                                _session.persistenceError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            if (_session.assessmentError != null)
                              Text(
                                _session.assessmentError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            const SizedBox(height: 12),
                            MyButton(
                              onPressed: () async {
                                await _session.advance();
                                if (_session.status ==
                                        SessionStatus.completed &&
                                    context.mounted) {
                                  if (_session.persistenceError != null) return;
                                  if (_session.assessmentError != null) return;
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 700),
                                  );
                                  if (!context.mounted) return;
                                  await context
                                      .read<SessionHistoryController>()
                                      .load();
                                  if (context.mounted) context.go('/results');
                                }
                              },
                              child: Text(
                                _session.currentIndex ==
                                        _session.questionCount - 1
                                    ? 'Finish session'
                                    : 'Next question',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text('Choose a visual theme: ${_theme.name}'),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final theme in CountingTheme.themes)
                                ChoiceChip(
                                  label: Text(theme.name),
                                  selected: _theme.id == theme.id,
                                  onSelected: (_) =>
                                      setState(() => _theme = theme),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : _session.status == SessionStatus.completed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListenableBuilder(
                          listenable: _mascot,
                          builder: (context, child) => MascotWidget(
                            state: _mascot.state,
                            celebrationId: _mascot.celebrationId,
                            size: 144,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Session complete!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : _session.status == SessionStatus.loading
                  ? const CircularProgressIndicator()
                  : Text(
                      _planningError ??
                          _session.persistenceError ??
                          _session.errorMessage ??
                          'Session is unavailable.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
            ),
            rectangularMenuArea: MyButton(
              onPressed: () => context.go('/levels'),
              child: const Text('Leave session'),
            ),
          ),
        );
      },
    );
  }
}

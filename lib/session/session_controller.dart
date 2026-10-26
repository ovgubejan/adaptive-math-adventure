import 'package:flutter/foundation.dart';

import '../content/level_catalog.dart';
import '../content/question_repository.dart';
import '../domain/adaptive_assessment.dart';
import '../domain/activity_answer.dart';
import '../domain/activity_content.dart';
import '../domain/math_question.dart';
import '../domain/session_result.dart';
import '../persistence/session_result_persistence.dart';
import '../persistence/adaptive_progress_repository.dart';
import '../persistence/memory_adaptive_progress_repository.dart';

enum SessionStatus { idle, loading, active, completed, failed }

class SessionController extends ChangeNotifier {
  final QuestionRepository _questionRepository;
  final SessionResultPersistence _persistence;
  final AdaptiveProgressRepository _adaptiveProgressRepository;
  final AdaptiveAssessmentEngine _assessmentEngine;
  final DateTime Function() _clock;

  SessionStatus _status = SessionStatus.idle;
  String? _levelId;
  List<MathQuestion> _questions = const [];
  final List<List<AnswerAttempt>> _attempts = [];
  int _currentIndex = 0;
  DateTime? _startedAt;
  DateTime? _questionStartedAt;
  bool _hintUsed = false;
  bool _canAdvance = false;
  bool? _lastAnswerCorrect;
  SessionResult? _result;
  String? _errorMessage;
  String? _persistenceError;
  AdaptiveAssessmentDecision? _assessmentDecision;
  String? _assessmentError;

  SessionController({
    required this._questionRepository,
    required this._persistence,
    AdaptiveProgressRepository? adaptiveProgressRepository,
    this._assessmentEngine = const AdaptiveAssessmentEngine(),
    DateTime Function()? clock,
  }) : _adaptiveProgressRepository =
           adaptiveProgressRepository ?? MemoryAdaptiveProgressRepository(),
       _clock = clock ?? DateTime.now;

  SessionStatus get status => _status;
  String? get levelId => _levelId;
  int get currentIndex => _currentIndex;
  int get questionCount => _questions.length;
  List<AnswerAttempt> get currentAttempts => _status == SessionStatus.active
      ? List.unmodifiable(_attempts[_currentIndex])
      : const [];
  MathQuestion? get currentQuestion =>
      _status == SessionStatus.active ? _questions[_currentIndex] : null;
  bool get canAdvance => _canAdvance;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;
  SessionResult? get result => _result;
  String? get errorMessage => _errorMessage;
  String? get persistenceError => _persistenceError;
  AdaptiveAssessmentDecision? get assessmentDecision => _assessmentDecision;
  String? get assessmentError => _assessmentError;

  Future<void> startSession(String levelId) async {
    if (!LevelCatalog.canLaunch(levelId)) {
      _status = SessionStatus.failed;
      _errorMessage = 'Level "$levelId" is unknown, locked, or unavailable.';
      notifyListeners();
      return;
    }

    final level = LevelCatalog.byId(levelId)!;
    final questions = _questionRepository.questionsFor(level).take(5).toList();
    if (questions.length != 5) {
      _fail('Level ${level.number} must provide exactly five questions.');
      return;
    }
    await _startQuestions(levelId, questions);
  }

  Future<void> startPlannedSession(
    String levelId,
    List<MathQuestion> questions,
  ) async {
    if (!LevelCatalog.canLaunch(levelId)) {
      _fail('Level "$levelId" is unknown, locked, or unavailable.');
      return;
    }
    final level = LevelCatalog.byId(levelId)!;
    if (questions.length != 5 ||
        questions.any(
          (question) =>
              !level.availableActivityTypes.contains(question.activityType),
        )) {
      _fail('The planned session is invalid for level "$levelId".');
      return;
    }
    await _startQuestions(levelId, questions);
  }

  Future<void> startDemoSession() =>
      _startQuestions('activity-demo', QuestionRepository.demoQuestions);

  Future<void> _startQuestions(
    String levelId,
    List<MathQuestion> questions,
  ) async {
    _status = SessionStatus.loading;
    _errorMessage = null;
    _persistenceError = null;
    _assessmentError = null;
    _assessmentDecision = null;
    notifyListeners();

    if (questions.isEmpty) {
      _fail('No questions are configured for this session.');
      return;
    }

    try {
      for (final question in questions) {
        if (question.levelId != levelId) {
          throw FormatException(
            'Question ${question.id} does not belong to $levelId.',
          );
        }
        ActivityContent.fromQuestion(question);
      }
    } on FormatException catch (error) {
      _fail(error.message);
      return;
    }

    _levelId = levelId;
    _questions = List.unmodifiable(questions);
    _attempts
      ..clear()
      ..addAll(List.generate(questions.length, (_) => <AnswerAttempt>[]));
    _currentIndex = 0;
    _startedAt = _clock();
    _questionStartedAt = _startedAt;
    _hintUsed = false;
    _canAdvance = false;
    _lastAnswerCorrect = null;
    _result = null;
    _status = SessionStatus.active;
    notifyListeners();
  }

  void _fail(String message) {
    _status = SessionStatus.failed;
    _errorMessage = message;
    notifyListeners();
  }

  void recordHintUsage() {
    if (_status != SessionStatus.active || _canAdvance) return;
    _hintUsed = true;
    notifyListeners();
  }

  bool submitAnswer(ActivityAnswer answer) {
    if (_status != SessionStatus.active || _canAdvance) return false;
    final question = _questions[_currentIndex];
    final now = _clock();
    final elapsed = now.difference(_questionStartedAt ?? now);
    final attempt = AnswerAttempt(
      answer: answer,
      isCorrect: answer == question.correctAnswer,
      responseTime: elapsed.isNegative ? Duration.zero : elapsed,
      hintUsed: _hintUsed,
    );
    _attempts[_currentIndex].add(attempt);
    _lastAnswerCorrect = attempt.isCorrect;
    _canAdvance = true;
    notifyListeners();
    return attempt.isCorrect;
  }

  Future<void> advance() async {
    if (_status != SessionStatus.active || !_canAdvance) return;
    if (_currentIndex == _questions.length - 1) {
      await _completeSession();
      return;
    }
    _currentIndex++;
    _questionStartedAt = _clock();
    _hintUsed = false;
    _canAdvance = false;
    _lastAnswerCorrect = null;
    notifyListeners();
  }

  Future<void> _completeSession() async {
    final completedAt = _clock();
    final evidence = [
      for (var index = 0; index < _questions.length; index++)
        QuestionEvidence(
          questionId: _questions[index].id,
          skillTag: _questions[index].skillTag,
          difficulty: _questions[index].difficulty,
          attempts: List.unmodifiable(_attempts[index]),
        ),
    ];
    final result = SessionResult(
      sessionId: '$_levelId-${completedAt.microsecondsSinceEpoch}',
      levelId: _levelId!,
      startedAt: _startedAt!,
      completedAt: completedAt,
      expectedQuestionCount: _questions.length,
      evidence: List.unmodifiable(evidence),
    );
    _result = result;
    _status = SessionStatus.completed;
    notifyListeners();

    try {
      await _persistence.saveResult(result);
    } catch (error) {
      _persistenceError = 'Session completed but could not be saved: $error';
      notifyListeners();
    }

    try {
      final states = await _adaptiveProgressRepository.loadAll();
      final previous = states.where((state) => state.levelId == result.levelId);
      final storedLevelState = previous.isEmpty
          ? AdaptiveProgressState.empty
          : previous.first;
      final completedLevelIds = {
        for (final state in states) ...state.completedLevelIds,
      };
      final historical = storedLevelState.levelId.isEmpty
          ? AdaptiveProgressState(
              levelId: result.levelId,
              mastery: 0,
              currentDifficulty: AdaptiveDifficulty.easy,
              completedSessionCount: 0,
              recentSessionScores: const [],
              masterySnapshots: const [],
              skillPerformance: const {},
              completedSessionIds: const [],
              successfulMediumSessionCount: 0,
              completedLevelIds: completedLevelIds.toList(),
            )
          : storedLevelState.copyWith(
              completedLevelIds: completedLevelIds.toList(),
            );
      final decision = _assessmentEngine.evaluate(
        result,
        historicalState: historical,
      );
      _assessmentDecision = decision;
      if (!storedLevelState.hasProcessed(result.sessionId)) {
        await _adaptiveProgressRepository.save(decision.updatedState);
      }
      notifyListeners();
    } catch (error) {
      _assessmentError =
          'Session saved, but adaptive assessment failed: $error';
      notifyListeners();
    }
  }
}

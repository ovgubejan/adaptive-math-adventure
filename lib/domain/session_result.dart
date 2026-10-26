class AnswerAttempt {
  final int answer;
  final bool isCorrect;
  final Duration responseTime;
  final bool hintUsed;

  const AnswerAttempt({
    required this.answer,
    required this.isCorrect,
    required this.responseTime,
    required this.hintUsed,
  });

  Map<String, Object> toJson() => {
    'answer': answer,
    'isCorrect': isCorrect,
    'responseTimeMs': responseTime.inMilliseconds,
    'hintUsed': hintUsed,
  };

  factory AnswerAttempt.fromJson(Map<String, dynamic> json) => AnswerAttempt(
    answer: json['answer'] as int,
    isCorrect: json['isCorrect'] as bool,
    responseTime: Duration(milliseconds: json['responseTimeMs'] as int),
    hintUsed: json['hintUsed'] as bool,
  );
}

class QuestionEvidence {
  final String questionId;
  final String skillTag;
  final int difficulty;
  final List<AnswerAttempt> attempts;

  const QuestionEvidence({
    required this.questionId,
    required this.skillTag,
    required this.difficulty,
    required this.attempts,
  });

  AnswerAttempt? get finalAttempt => attempts.isEmpty ? null : attempts.last;

  Map<String, Object> toJson() => {
    'questionId': questionId,
    'skillTag': skillTag,
    'difficulty': difficulty,
    'attempts': attempts.map((attempt) => attempt.toJson()).toList(),
  };

  factory QuestionEvidence.fromJson(
    Map<String, dynamic> json,
  ) => QuestionEvidence(
    questionId: json['questionId'] as String,
    skillTag: json['skillTag'] as String,
    difficulty: json['difficulty'] as int,
    attempts: (json['attempts'] as List<dynamic>)
        .map(
          (attempt) =>
              AnswerAttempt.fromJson(Map<String, dynamic>.from(attempt as Map)),
        )
        .toList(),
  );
}

class SessionResult {
  final String sessionId;
  final String levelId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int? expectedQuestionCount;
  final List<QuestionEvidence> evidence;

  const SessionResult({
    required this.sessionId,
    required this.levelId,
    required this.startedAt,
    required this.completedAt,
    required this.evidence,
    this.expectedQuestionCount,
  });

  int get totalQuestions => evidence.length;

  int get correctCount =>
      evidence.where((item) => item.finalAttempt?.isCorrect ?? false).length;

  double get accuracy =>
      totalQuestions == 0 ? 0 : correctCount / totalQuestions;

  Duration get totalResponseTime => evidence.fold(
    Duration.zero,
    (total, item) =>
        total +
        item.attempts.fold(
          Duration.zero,
          (questionTotal, attempt) => questionTotal + attempt.responseTime,
        ),
  );

  Map<String, Object?> toJson() => {
    'sessionId': sessionId,
    'levelId': levelId,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'expectedQuestionCount': expectedQuestionCount,
    'evidence': evidence.map((item) => item.toJson()).toList(),
  };

  factory SessionResult.fromJson(Map<String, dynamic> json) => SessionResult(
    sessionId: json['sessionId'] as String,
    levelId: json['levelId'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: DateTime.parse(json['completedAt'] as String),
    expectedQuestionCount: json['expectedQuestionCount'] as int?,
    evidence: (json['evidence'] as List<dynamic>)
        .map(
          (item) =>
              QuestionEvidence.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
  );
}

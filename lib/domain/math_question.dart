import 'activity_type.dart';

class MathQuestion {
  final String id;
  final String levelId;
  final ActivityType activityType;
  final String skillTag;
  final int difficulty;
  final Map<String, Object> data;
  final int correctAnswer;

  const MathQuestion({
    required this.id,
    required this.levelId,
    required this.activityType,
    required this.skillTag,
    required this.difficulty,
    required this.data,
    required this.correctAnswer,
  });
}
